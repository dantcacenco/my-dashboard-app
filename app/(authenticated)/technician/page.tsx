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
  const { data: jobAssignments, error: jobError } = await supabase
    .from('job_technicians')
    .select(`
      job_id,
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
    .order('created_at', { ascending: false })

  console.log('Debug - Job assignments query result:', jobAssignments)
  console.log('Debug - Job assignments error:', jobError)

  // Extract jobs from assignments (handle the nested structure)
  const jobs = jobAssignments?.map(assignment => assignment.jobs).filter(Boolean).flat() || []

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
