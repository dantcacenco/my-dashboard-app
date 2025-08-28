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
  
  console.log('JobsPage - User role:', userRole, 'User ID:', user.id)

  let jobs = []

  if (userRole === 'technician') {
    // First, get job IDs assigned to this technician
    const { data: assignments, error: assignmentError } = await supabase
      .from('job_technicians')
      .select('job_id')
      .eq('technician_id', user.id)
    
    console.log('Technician assignments:', assignments, 'Error:', assignmentError)
    
    if (assignments && assignments.length > 0) {
      const jobIds = assignments.map(a => a.job_id)
      
      // Then fetch those jobs with customer info
      const { data: techJobs, error: jobsError } = await supabase
        .from('jobs')
        .select(`
          *,
          customers!customer_id (
            name,
            email,
            phone,
            address
          ),
          proposals!proposal_id (
            id,
            status
          )
        `)
        .in('id', jobIds)
        .order('created_at', { ascending: false })
      
      console.log('Technician jobs:', techJobs?.length, 'Error:', jobsError)
      jobs = techJobs || []
    }
  } else {
    // Boss/admin sees all jobs
    const { data: allJobs, error } = await supabase
      .from('jobs')
      .select(`
        *,
        customers!customer_id (
          name,
          email,
          phone,
          address
        ),
        proposals!proposal_id (
          id,
          status
        )
      `)
      .order('created_at', { ascending: false })
    
    console.log('All jobs for boss/admin:', allJobs?.length, 'Error:', error)
    jobs = allJobs || []
  }

  return (
    <div className="container mx-auto py-6 px-4">
      <JobsListHeader userRole={userRole} />
      {userRole === 'technician' && jobs.length === 0 ? (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <p className="text-yellow-800">No jobs assigned to you yet.</p>
          <p className="text-sm text-yellow-600 mt-1">Jobs will appear here once your supervisor assigns them to you.</p>
        </div>
      ) : (
        <JobsList jobs={jobs} userRole={userRole} />
      )}
    </div>
  )
}
