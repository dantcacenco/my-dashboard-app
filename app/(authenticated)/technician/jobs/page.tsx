import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianJobsList from './TechnicianJobsList'

export default async function TechnicianJobsPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role, full_name')
    .eq('id', user.id)
    .single()

  // Only technicians can access this
  if (profile?.role !== 'technician') {
    redirect('/')
  }

  // Get jobs assigned to this technician - using a more specific query
  const { data: assignedJobs, error } = await supabase
    .from('job_technicians')
    .select(`
      job_id,
      assigned_at,
      jobs!inner (
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
        customer_name,
        customer_phone,
        customer_email,
        created_at
      )
    `)
    .eq('technician_id', user.id)
    .order('assigned_at', { ascending: false })

  if (error) {
    console.error('Error fetching technician jobs:', error)
  }

  // Flatten the jobs data
  const jobs = assignedJobs?.map(item => ({
    ...item.jobs,
    assigned_at: item.assigned_at
  })).filter(Boolean) || []

  // Additionally fetch photos and files for each job
  for (const job of jobs) {
    const { data: photos } = await supabase
      .from('job_photos')
      .select('id, photo_url, caption, created_at')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    const { data: files } = await supabase
      .from('job_files')
      .select('id, file_name, file_url, created_at')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    job.job_photos = photos || []
    job.job_files = files || []
  }

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">My Jobs</h1>
        <p className="text-gray-600">Welcome back, {profile?.full_name || 'Technician'}</p>
      </div>
      
      <TechnicianJobsList jobs={jobs} technicianId={user.id} />
    </div>
  )
}
