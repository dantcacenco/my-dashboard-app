import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { redirect } from 'next/navigation'
import TechniciansClientView from './TechniciansClientView'

export const dynamic = 'force-dynamic'
export const revalidate = 0

export default async function TechniciansPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'boss') {
    redirect('/dashboard')
  }

  // Use admin client to get technicians (bypasses RLS)
  let technicians = []
  try {
    const adminClient = createAdminClient()
    const { data } = await adminClient
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
      .order('created_at', { ascending: false })
    
    technicians = data || []
  } catch (error) {
    console.error('Error fetching technicians:', error)
  }

  return <TechniciansClientView technicians={technicians} />
}
