import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianJobDetailView from '../TechnicianJobDetailView'

export default async function TechnicianJobDetailPage({ 
  params 
}: { 
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only technicians can access this
  if (profile?.role !== 'technician') {
    redirect('/')
  }

  // Verify technician is assigned to this job
  const { data: assignment } = await supabase
    .from('job_technicians')
    .select('id')
    .eq('job_id', id)
    .eq('technician_id', user.id)
    .single()

  if (!assignment) {
    redirect('/technician/jobs')
  }

  return <TechnicianJobDetailView jobId={id} userId={user.id} />
}
