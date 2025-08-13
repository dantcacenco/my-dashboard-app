import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import CustomerDetailView from './CustomerDetailView'

export default async function CustomerDetailPage({ 
  params 
}: { 
  params: Promise<{ id: string }> 
}) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const { data: customer, error } = await supabase
    .from('customers')
    .select(`
      *,
      proposals (
        *,
        proposal_items (*)
      ),
      jobs (
        *,
        job_proposals (
          proposal_id
        )
      )
    `)
    .eq('id', id)
    .single()

  if (error || !customer) {
    notFound()
  }

  return (
    <CustomerDetailView 
      customer={customer} 
      userRole={profile?.role || 'technician'}
    />
  )
}
