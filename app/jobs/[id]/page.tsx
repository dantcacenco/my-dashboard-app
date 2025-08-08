import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobDetailView from './JobDetailView'

export default async function JobDetailPage({
  params
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const supabase = await createClient()
  
  // Check authentication
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/sign-in')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Get job details
  const { data: job, error } = await supabase
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
      proposals (
        id,
        proposal_number,
        total
      ),
      assigned_technician:profiles!jobs_assigned_technician_id_fkey (
        id,
        full_name,
        email,
        phone
      ),
      job_time_entries (
        id,
        clock_in_time,
        clock_out_time,
        total_hours,
        is_edited,
        edit_reason
      ),
      job_photos (
        id,
        photo_url,
        photo_type,
        caption,
        created_at
      ),
      job_materials (
        id,
        material_name,
        model_number,
        serial_number,
        quantity,
        created_at
      )
    `)
    .eq('id', id)
    .single()

  if (error || !job) {
    redirect('/jobs')
  }

  // Check access - technicians can only see their assigned jobs
  if (profile?.role === 'technician' && job.assigned_technician_id !== user.id) {
    redirect('/jobs')
  }

  return (
    <JobDetailView 
      job={job}
      userRole={profile?.role || 'technician'}
      userId={user.id}
    />
  )
}
