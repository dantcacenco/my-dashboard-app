import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import JobDetailView from './JobDetailView'

export default async function JobDetailPage({ 
  params 
}: { 
  params: Promise<{ id: string }> 
}) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: job, error } = await supabase
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
        title,
        total
      )
    `)
    .eq('id', id)
    .single()

  if (error || !job) {
    notFound()
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const { data: technicians } = await supabase
    .from('profiles')
    .select('id, full_name, email')
    .eq('role', 'technician')
    .eq('is_active', true)

  return (
    <JobDetailView 
      job={job} 
      userRole={profile?.role || 'technician'}
      availableTechnicians={technicians || []}
    />
  )
}
