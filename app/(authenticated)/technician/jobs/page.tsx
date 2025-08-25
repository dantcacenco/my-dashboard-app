import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianJobsList from './TechnicianJobsList'

export default async function TechnicianJobsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  // Verify technician role
  if (profile?.role !== 'technician') {
    redirect('/')
  }

  // Get jobs assigned to this technician
  const { data: jobs } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
        name,
        email,
        phone,
        address
      ),
      proposals (
        proposal_number,
        title
      )
    `)
    .eq('assigned_technician_id', user.id)
    .order('scheduled_date', { ascending: true })

  // Format jobs data
  const formattedJobs = jobs?.map(job => ({
    ...job,
    assigned_at: job.assigned_at || job.created_at
  })) || []

  return <TechnicianJobsList jobs={formattedJobs} technicianId={user.id} />
}
