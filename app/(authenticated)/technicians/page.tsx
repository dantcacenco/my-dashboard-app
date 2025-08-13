import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechniciansView from './TechniciansView'
import FixOrphanedButton from './FixOrphanedButton'

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

  const { data: technicians } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'technician')
    .order('full_name', { ascending: true })

  return (
    <>
      <div className="p-6 pb-0">
        <div className="flex justify-end">
          <FixOrphanedButton />
        </div>
      </div>
      <TechniciansView technicians={technicians || []} />
    </>
  )
}
