import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobsList from './JobsList'

export default async function JobsPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/login')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (!profile) {
    redirect('/auth/login')
  }

  // Get jobs based on role
  let jobsQuery = supabase
    .from('jobs')
    .select(`
      *,
      customers (*),
      job_proposals (
        proposal_id,
        proposals (
          proposal_number,
          title,
          total
        )
      ),
      tasks (count)
    `)
    .order('created_at', { ascending: false })

  // Technicians only see jobs with their tasks
  if (profile.role === 'technician') {
    // This would need to be refined to show only jobs with tasks assigned to this technician
    jobsQuery = jobsQuery
  }

  const { data: jobs } = await jobsQuery

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Jobs</h1>
      </div>
      
      <JobsList jobs={jobs || []} userRole={profile.role} />
    </div>
  )
}
