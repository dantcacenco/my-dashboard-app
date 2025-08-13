import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechniciansList from './TechniciansList'

export default async function TechniciansPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/login')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only allow boss to view technicians page
  if (profile?.role !== 'boss') {
    redirect('/dashboard')
  }

  // Get all technicians
  const { data: technicians } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'technician')
    .order('created_at', { ascending: false })

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">Technicians</h1>
          <p className="text-gray-600">Manage your technician team</p>
        </div>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          Add Technician
        </button>
      </div>
      
      <TechniciansList technicians={technicians || []} />
    </div>
  )
}
