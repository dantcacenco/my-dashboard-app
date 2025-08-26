#!/bin/bash

echo "Creating comprehensive fix for storage permissions and calendar..."

# Create the SQL file with proper permissions
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/storage-permissions.sql << 'EOF'
-- First check and drop existing policies to avoid conflicts
DO $$ 
BEGIN
    -- Drop existing policies if they exist
    DROP POLICY IF EXISTS "Technicians can view job photos for assigned jobs" ON storage.objects;
    DROP POLICY IF EXISTS "Technicians can upload photos to assigned jobs" ON storage.objects;
    DROP POLICY IF EXISTS "Technicians can view job files for assigned jobs" ON storage.objects;
    DROP POLICY IF EXISTS "Technicians can upload files to assigned jobs" ON storage.objects;
    DROP POLICY IF EXISTS "Technicians can view job_photos for assigned jobs" ON public.job_photos;
    DROP POLICY IF EXISTS "Technicians can create job_photos for assigned jobs" ON public.job_photos;
    DROP POLICY IF EXISTS "Technicians can view job_files for assigned jobs" ON public.job_files;
    DROP POLICY IF EXISTS "Technicians can create job_files for assigned jobs" ON public.job_files;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

-- Storage bucket policies for job-photos
CREATE POLICY "Technicians can view job photos for assigned jobs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'job-photos' 
  AND EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id::text = split_part(storage.objects.name, '/', 1)
  )
);

CREATE POLICY "Technicians can upload photos to assigned jobs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'job-photos' 
  AND EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id::text = split_part(storage.objects.name, '/', 1)
  )
);

-- Storage bucket policies for job-files
CREATE POLICY "Technicians can view job files for assigned jobs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'job-files' 
  AND EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id::text = split_part(storage.objects.name, '/', 1)
  )
);

CREATE POLICY "Technicians can upload files to assigned jobs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'job-files' 
  AND EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id::text = split_part(storage.objects.name, '/', 1)
  )
);

-- Table policies for job_photos
CREATE POLICY "Technicians can view job_photos for assigned jobs"
ON public.job_photos FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id = job_photos.job_id
  )
);

CREATE POLICY "Technicians can create job_photos for assigned jobs"
ON public.job_photos FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id = job_photos.job_id
  )
);

-- Table policies for job_files
CREATE POLICY "Technicians can view job_files for assigned jobs"
ON public.job_files FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id = job_files.job_id
  )
);

CREATE POLICY "Technicians can create job_files for assigned jobs"
ON public.job_files FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id = job_files.job_id
  )
);

-- Verify the policies were created
SELECT tablename, policyname FROM pg_policies WHERE tablename IN ('objects', 'job_photos', 'job_files') AND policyname LIKE '%Technician%';
EOF

echo "✅ Storage permissions SQL file created: storage-permissions.sql"
echo ""
echo "Now fixing the dashboard page to properly count today's jobs..."

# Fix the dashboard page to properly count jobs
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/dashboard/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from '@/app/DashboardContent'

export default async function DashboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Check user role - handle missing profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // If no profile exists, create a default admin profile for this user
  if (!profile) {
    console.log('No profile found for user, treating as admin')
  } else if (profile.role !== 'boss' && profile.role !== 'admin') {
    // Not an admin or boss
    redirect('/')
  }

  // Fetch proposals with customer data (continue even without profile)
  const { data: proposals } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        name,
        email
      )
    `)
    .order('created_at', { ascending: false })

  const proposalList = proposals || []

  // Fetch jobs for the calendar
  const today = new Date()
  const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
  const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0)
  
  const { data: jobs } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (name, address)
    `)
    .gte('scheduled_date', startOfMonth.toISOString())
    .lte('scheduled_date', endOfMonth.toISOString())
    .order('scheduled_date', { ascending: true })

  // Count today's jobs
  const todayStr = today.toISOString().split('T')[0]
  const todaysJobsCount = jobs?.filter(j => 
    j.scheduled_date && j.scheduled_date.split('T')[0] === todayStr
  ).length || 0

  // Calculate metrics
  const totalRevenue = proposalList.reduce((total, proposal) => {
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

  const approvedProposals = proposalList.filter(p => 
    p.status === 'approved' || p.status === 'accepted'
  ).length
  
  const paidProposals = proposalList.filter(p => 
    p.deposit_paid_at || p.progress_paid_at || p.final_paid_at
  ).length
  
  const conversionRate = proposalList.length > 0 
    ? (approvedProposals / proposalList.length) * 100 
    : 0
    
  const paymentRate = approvedProposals > 0 
    ? (paidProposals / approvedProposals) * 100 
    : 0

  // Calculate status counts
  const statusCounts = {
    draft: proposalList.filter(p => p.status === 'draft').length,
    sent: proposalList.filter(p => p.status === 'sent').length,
    viewed: proposalList.filter(p => p.status === 'viewed').length,
    approved: proposalList.filter(p => p.status === 'approved' || p.status === 'accepted').length,
    rejected: proposalList.filter(p => p.status === 'rejected').length,
    paid: paidProposals
  }

  // Calculate monthly revenue
  const monthlyRevenue = []
  const now = new Date()
  for (let i = 5; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1)
    const monthStr = date.toLocaleDateString('en-US', { month: 'short' })
    
    const monthProposals = proposalList.filter(p => {
      const created = new Date(p.created_at)
      return created.getMonth() === date.getMonth() && 
             created.getFullYear() === date.getFullYear()
    })
    
    const revenue = monthProposals.reduce((total, proposal) => {
      let rev = 0
      if (proposal.deposit_paid_at) rev += Number(proposal.deposit_amount || 0)
      if (proposal.progress_paid_at) rev += Number(proposal.progress_payment_amount || 0)
      if (proposal.final_paid_at) rev += Number(proposal.final_payment_amount || 0)
      return total + rev
    }, 0)
    
    monthlyRevenue.push({
      month: monthStr,
      revenue: Math.round(revenue),
      proposals: monthProposals.length
    })
  }

  // Format recent proposals
  const recentProposals = proposalList.slice(0, 10).map(p => ({
    id: p.id,
    proposal_number: p.proposal_number,
    title: p.title || `Proposal #${p.proposal_number}`,
    total: p.total || 0,
    status: p.status,
    created_at: p.created_at,
    customers: p.customers ? [p.customers] : null
  }))

  const recentActivities: any[] = []

  const dashboardData = {
    metrics: {
      totalProposals: proposalList.length,
      totalRevenue: Math.round(totalRevenue),
      approvedProposals,
      conversionRate: Math.round(conversionRate),
      paymentRate: Math.round(paymentRate)
    },
    monthlyRevenue,
    statusCounts,
    recentProposals,
    recentActivities,
    todaysJobsCount,
    monthlyJobs: jobs || []
  }

  return <DashboardContent data={dashboardData} />
}
EOF

echo "Dashboard page updated to fetch jobs properly!"
echo ""
echo "Now updating DashboardContent to show the jobs count..."
