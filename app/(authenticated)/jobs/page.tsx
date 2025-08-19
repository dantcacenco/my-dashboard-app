import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobsList from './JobsList'
import JobsListHeader from './JobsListHeader'

export default async function JobsPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const userRole = profile?.role || 'technician'

  // Fetch jobs based on role
  let query = supabase
    .from('jobs')
    .select(`
      *,
      customers!customer_id (
        name,
        email,
        phone,
        address
      )
    `)
    .order('created_at', { ascending: false })

  // If technician, only show their assigned jobs
  if (userRole === 'technician') {
    const { data: assignedJobs } = await supabase
      .from('job_technicians')
      .select('job_id')
      .eq('technician_id', user.id)

    const jobIds = assignedJobs?.map(j => j.job_id) || []
    if (jobIds.length > 0) {
      query = query.in('id', jobIds)
    } else {
      // No assigned jobs, return empty
      return (
        <div className="container mx-auto py-6 px-4">
          <JobsListHeader />
          <p className="text-gray-500">No jobs assigned to you.</p>
        </div>
      )
    }
  }

  const { data: jobs, error } = await query

  if (error) {
    console.error('Error fetching jobs:', error)
    return <div>Error loading jobs</div>
  }

  return (
    <div className="container mx-auto py-6 px-4">
      <JobsListHeader />
      <JobsList jobs={jobs || []} userRole={userRole} />
    </div>
  )
}
