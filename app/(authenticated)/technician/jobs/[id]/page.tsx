import { createClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import TechnicianJobView from './TechnicianJobView'

export default async function TechnicianJobPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/signin')

  // Check if user is a technician
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (!profile || profile.role !== 'technician') {
    redirect('/')
  }

  // Check if this technician is assigned to this job
  const { data: assignment } = await supabase
    .from('job_technicians')
    .select('*')
    .eq('job_id', id)
    .eq('technician_id', user.id)
    .single()

  if (!assignment) {
    // Technician is not assigned to this job
    redirect('/technician')
  }

  // Get job details with proposal data
  const { data: job } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
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
    .eq('id', id)
    .single()

  if (!job) {
    notFound()
  }

  return <TechnicianJobView job={job} userId={user.id} />
}
