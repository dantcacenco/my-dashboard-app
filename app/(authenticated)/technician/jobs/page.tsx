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
