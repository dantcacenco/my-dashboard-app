import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianJobsList from './TechnicianJobsList'

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

  // First get the job IDs assigned to this technician
  const { data: assignments } = await supabase
    .from('job_technicians')
    .select('job_id')
    .eq('technician_id', user.id)

  const jobIds = assignments?.map(a => a.job_id) || []

  // Now get the full job details for these job IDs
  let jobs = []
  if (jobIds.length > 0) {
    const { data: jobData } = await supabase
      .from('jobs')
      .select(`
        *,
        customers (
          id,
          name,
          email,
          phone,
          address
        ),
        proposals:proposal_id (
          id,
          status,
          total,
          deposit_amount,
          progress_payment_amount,
          final_payment_amount,
          deposit_paid_at,
          progress_paid_at,
          final_paid_at
        )
      `)
      .in('id', jobIds)
      .order('created_at', { ascending: false })

    jobs = jobData || []
  }

  return <TechnicianJobsList jobs={jobs} technicianName={profile.full_name || user.email || 'Technician'} />
}
