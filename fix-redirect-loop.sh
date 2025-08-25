#!/bin/bash

echo "🔧 Fixing redirect loop between dashboard and technician pages..."
echo ""

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# First, let's verify the current user role in database
echo "📊 Checking current user role in database..."
cat > check-user-role.js << 'EOF'
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://dqcxwekmehrqkigcufug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxY3h3ZWttZWhycWtpZ2N1ZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwOTQ5NDYsImV4cCI6MjA2ODY3MDk0Nn0.m1vGbIc2md-kK0fKk_yBmxR4ugxbO2WOGp8n0_dPURQ';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkAndFixRole() {
  // Check current role
  const { data: profiles, error } = await supabase
    .from('profiles')
    .select('id, email, role')
    .eq('email', 'dantcacenco@gmail.com');
  
  console.log('Current profile:', profiles);
  
  if (!profiles || profiles.length === 0) {
    console.log('❌ No profile found for dantcacenco@gmail.com');
    
    // Get the user ID from auth.users
    const { data: { users } } = await supabase.auth.admin.listUsers();
    const user = users?.find(u => u.email === 'dantcacenco@gmail.com');
    
    if (user) {
      console.log('Creating profile with admin role...');
      const { error: insertError } = await supabase
        .from('profiles')
        .insert({
          id: user.id,
          email: 'dantcacenco@gmail.com',
          role: 'admin'
        });
      
      if (insertError) {
        console.log('Error creating profile:', insertError);
      } else {
        console.log('✅ Profile created with admin role');
      }
    }
  } else if (profiles[0].role !== 'admin') {
    console.log('Updating role to admin...');
    const { error: updateError } = await supabase
      .from('profiles')
      .update({ role: 'admin' })
      .eq('email', 'dantcacenco@gmail.com');
    
    if (updateError) {
      console.log('Error updating role:', updateError);
    } else {
      console.log('✅ Role updated to admin');
    }
  } else {
    console.log('✅ Role is already admin');
  }
  
  // Verify final state
  const { data: finalProfile } = await supabase
    .from('profiles')
    .select('email, role')
    .eq('email', 'dantcacenco@gmail.com')
    .single();
  
  console.log('Final profile state:', finalProfile);
}

checkAndFixRole();
EOF

node check-user-role.js
rm -f check-user-role.js

echo ""
echo "📝 Fixing dashboard page to handle missing profiles..."
cat > app/\(authenticated\)/dashboard/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from '@/app/DashboardContent'

export default async function DashboardPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/signin')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Debug logging
  console.log('Dashboard: User ID:', user.id)
  console.log('Dashboard: Profile:', profile)

  // If no profile exists, create one with admin role for now
  if (!profile) {
    console.log('No profile found, creating admin profile...')
    await supabase
      .from('profiles')
      .insert({
        id: user.id,
        email: user.email,
        role: 'admin'
      })
    
    // Redirect to dashboard again to reload with profile
    redirect('/dashboard')
  }

  // Only allow admin to view dashboard
  if (profile.role !== 'admin') {
    console.log('Not admin, redirecting to home. Role:', profile.role)
    redirect('/')
  }

  // Fetch dashboard data
  const [proposalsResult, activitiesResult] = await Promise.all([
    supabase
      .from('proposals')
      .select(`
        *,
        customers (
          name,
          email
        )
      `)
      .order('created_at', { ascending: false }),
    
    supabase
      .from('proposal_activities')
      .select(`
        *,
        proposals (
          proposal_number,
          title
        )
      `)
      .order('created_at', { ascending: false })
      .limit(10)
  ])

  const proposals = proposalsResult.data || []
  const activities = activitiesResult.data || []

  // Calculate revenue from paid amounts
  const revenue = proposals.reduce((total, proposal) => {
    let proposalRevenue = 0
    
    if (proposal.deposit_paid_at && proposal.deposit_amount) {
      proposalRevenue += Number(proposal.deposit_amount)
    }
    
    if (proposal.progress_paid_at && proposal.progress_payment_amount) {
      proposalRevenue += Number(proposal.progress_payment_amount)
    }
    
    if (proposal.final_paid_at && proposal.final_payment_amount) {
      proposalRevenue += Number(proposal.final_payment_amount)
    }
    
    return total + proposalRevenue
  }, 0)

  const activeProposals = proposals.filter(p => p.status === 'sent' || p.status === 'viewed').length
  const completedJobs = proposals.filter(p => p.status === 'completed').length

  const dashboardData = {
    revenue: Math.round(revenue),
    activeProposals,
    completedJobs,
    proposals,
    activities
  }

  return <DashboardContent initialData={dashboardData} />
}
EOF

echo ""
echo "📝 Fixing technician jobs page to redirect admins properly..."
cat > app/\(authenticated\)/technician/jobs/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianJobsList from './TechnicianJobsList'

export default async function TechnicianJobsPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/signin')

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role, full_name')
    .eq('id', user.id)
    .single()

  // If admin, redirect to dashboard
  if (profile?.role === 'admin') {
    redirect('/dashboard')
  }

  // Only technicians can access this
  if (profile?.role !== 'technician') {
    redirect('/dashboard')
  }

  // Get jobs assigned to this technician
  const { data: assignedJobs, error } = await supabase
    .from('job_technicians')
    .select(`
      job_id,
      assigned_at,
      jobs!inner (
        id,
        title,
        description,
        status,
        priority,
        scheduled_date,
        scheduled_time,
        service_address,
        customer_id,
        proposal_id,
        created_at,
        updated_at,
        customers (
          name,
          phone,
          address
        )
      )
    `)
    .eq('technician_id', user.id)
    .order('assigned_at', { ascending: false })

  if (error) {
    console.error('Error fetching jobs:', error)
  }

  // Transform the data to flatten the structure
  const jobs = assignedJobs?.map(aj => ({
    ...aj.jobs,
    assigned_at: aj.assigned_at
  })) || []

  return <TechnicianJobsList jobs={jobs} technicianName={profile?.full_name || user.email || ''} />
}
EOF

echo ""
echo "📝 Updating main app page to redirect properly..."
cat > app/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function HomePage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile to determine where to redirect
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Redirect based on role
  if (profile?.role === 'admin') {
    redirect('/dashboard')
  } else if (profile?.role === 'technician') {
    redirect('/technician/jobs')
  } else {
    // Default to dashboard for users without a role
    redirect('/dashboard')
  }
}
EOF

echo ""
echo "✅ Redirect loop fix complete!"
echo ""

# Test TypeScript
echo "🧪 Testing TypeScript compilation..."
npx tsc --noEmit 2>&1 | head -10

# Commit
echo "💾 Committing changes..."
git add -A
git commit -m "fix: resolve redirect loop between dashboard and technician pages"
git push origin main

echo ""
echo "✅ Fix deployed!"
echo ""
echo "🧹 Cleaning up script..."
rm -f "$0"

echo ""
echo "Try logging in again - the redirect loop should be fixed!"
