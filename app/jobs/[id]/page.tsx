import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobDetailView from './JobDetailView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function JobDetailPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/signin')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (!profile) {
    redirect('/auth/signin')
  }

  // Get job with all related data
  const { data: job } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (*),
      job_proposals (
        proposal_id,
        proposals (
          proposal_number,
          title,
          total,
          status
        )
      ),
      tasks (
        *,
        task_technicians (
          technician_id,
          profiles (
            full_name,
            email,
            phone
          )
        )
      )
    `)
    .eq('id', id)
    .single()

  if (!job) {
    redirect('/jobs')
  }

  return (
    <div className="p-6">
      <JobDetailView job={job} userRole={profile.role} userId={user.id} />
    </div>
  )
}
