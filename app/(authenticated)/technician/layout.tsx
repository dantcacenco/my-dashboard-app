import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function TechnicianLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only technicians can access this section
  if (profile?.role !== 'technician') {
    redirect('/dashboard')
  }

  return <>{children}</>
}
