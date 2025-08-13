import { createClient } from '@/lib/supabase/server'
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

  // Only boss/admin can manage technicians
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/dashboard')
  }

  // Get ALL technicians - simplified query
  const { data: technicians, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'technician')
    .order('created_at', { ascending: false })

  console.log('Technicians found:', technicians?.length || 0)
  if (error) console.error('Error fetching technicians:', error)

  return <TechniciansClientView technicians={technicians || []} />
}
