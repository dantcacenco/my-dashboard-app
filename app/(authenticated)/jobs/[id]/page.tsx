import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobDetailsView from './JobDetailsView'

export default async function JobDetailsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()

  // Check authentication
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/login')
  }

  // Check if user is admin/boss
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  // Fetch job details with related data
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
        status,
        total
      ),
      profiles:technician_id (
        id,
        full_name,
        email
      )
    `)
    .eq('id', id)
    .single()

  if (error || !job) {
    redirect('/jobs')
  }

  // Fetch job photos with debug logging
  const { data: jobPhotos } = await supabase
    .from('job_photos')
    .select('*')
    .eq('job_id', id)
    .order('created_at', { ascending: true })

  // Fetch job files
  const { data: jobFiles } = await supabase
    .from('job_files')
    .select('*')
    .eq('job_id', id)
    .order('created_at', { ascending: false })

  // Log for debugging
  console.log('[Server] Job photos fetched:', jobPhotos?.length || 0, 'photos')
  console.log('[Server] Job files fetched:', jobFiles?.length || 0, 'files')

  return (
    <JobDetailsView 
      job={job}
      jobPhotos={jobPhotos || []}
      jobFiles={jobFiles || []}
    />
  )
}
