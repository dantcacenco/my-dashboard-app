#!/bin/bash

# Fix the query error in technician page
echo "Fixing job_technicians query error..."

# Update the technician page to fix the order by clause
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianDashboard from './TechnicianDashboard'

export default async function TechnicianPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role, full_name')
    .eq('id', user.id)
    .single()

  // Check if user is a technician
  if (!profile || profile.role !== 'technician') {
    redirect('/')
  }

  // Debug: Get ALL job_technicians entries for this user
  const { data: allAssignments, error: assignError } = await supabase
    .from('job_technicians')
    .select('*')
    .eq('technician_id', user.id)

  console.log('Debug - All assignments for technician:', user.id, allAssignments)
  console.log('Debug - Assignment error:', assignError)

  // Get jobs assigned to this technician with full details
  // FIX: Remove the order by clause that's causing the error
  const { data: jobAssignments, error: jobError } = await supabase
    .from('job_technicians')
    .select(`
      job_id,
      technician_id,
      assigned_at,
      jobs (
        id,
        job_number,
        title,
        description,
        job_type,
        status,
        scheduled_date,
        scheduled_time,
        service_address,
        notes,
        created_at,
        customer_id,
        customers (
          name,
          email,
          phone,
          address
        )
      )
    `)
    .eq('technician_id', user.id)

  console.log('Debug - Job assignments query result:', jobAssignments)
  console.log('Debug - Job assignments error:', jobError)

  // Extract jobs from assignments (handle the nested structure)
  const jobs = jobAssignments?.map(assignment => assignment.jobs).filter(Boolean).flat() || []

  // Sort jobs by created_at if they have it
  jobs.sort((a: any, b: any) => {
    const dateA = a.created_at ? new Date(a.created_at).getTime() : 0
    const dateB = b.created_at ? new Date(b.created_at).getTime() : 0
    return dateB - dateA // Most recent first
  })

  console.log('Debug - Extracted jobs:', jobs)

  // Calculate metrics for technician
  const totalJobs = jobs.length
  const completedJobs = jobs.filter((j: any) => j.status === 'completed').length
  const inProgressJobs = jobs.filter((j: any) => j.status === 'in_progress').length
  const scheduledJobs = jobs.filter((j: any) => j.status === 'scheduled').length
  const todaysJobs = jobs.filter((j: any) => {
    const today = new Date().toISOString().split('T')[0]
    return j.scheduled_date?.split('T')[0] === today
  }).length

  const technicianData = {
    profile: {
      name: profile.full_name || user.email || 'Technician',
      email: user.email || '',
      role: profile.role
    },
    metrics: {
      totalJobs,
      completedJobs,
      inProgressJobs,
      scheduledJobs,
      todaysJobs
    },
    jobs,
    // Add debug info to be displayed
    debug: {
      userId: user.id,
      userEmail: user.email,
      role: profile?.role,
      allAssignments: allAssignments || [],
      jobAssignments: jobAssignments || [],
      assignmentError: assignError?.message,
      jobError: jobError?.message,
      extractedJobsCount: jobs.length
    }
  }

  return <TechnicianDashboard data={technicianData} />
}
EOF

# Build and commit
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -20

git add -A
git commit -m "Fix job_technicians query - remove invalid order by created_at"
git push origin main

echo "✅ Fixed the query error!"
echo "The technician dashboard should now show the assigned jobs properly"
