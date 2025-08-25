import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'

export default async function TechnicianPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Check user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // IMPORTANT: Technician stays here, admin goes to dashboard
  if (profile?.role === 'boss') {
    redirect('/dashboard')
  }

  // Non-technicians go to home
  if (profile?.role !== 'technician') {
    redirect('/')
  }

  // Get technician's stats
  const { data: jobs } = await supabase
    .from('jobs')
    .select('*')
    .eq('assigned_technician_id', user.id)

  const activeJobs = jobs?.filter(j => j.status === 'in_progress').length || 0
  const completedJobs = jobs?.filter(j => j.status === 'completed').length || 0
  const scheduledJobs = jobs?.filter(j => j.status === 'scheduled').length || 0

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Technician Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-sm font-medium text-gray-500">Active Jobs</h3>
          <p className="text-2xl font-bold mt-2">{activeJobs}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-sm font-medium text-gray-500">Scheduled</h3>
          <p className="text-2xl font-bold mt-2">{scheduledJobs}</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-sm font-medium text-gray-500">Completed</h3>
          <p className="text-2xl font-bold mt-2">{completedJobs}</p>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow">
        <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
        <div className="space-y-2">
          <Link href="/technician/jobs" className="block p-3 bg-blue-50 rounded hover:bg-blue-100">
            View My Jobs →
          </Link>
          <Link href="/technician/schedule" className="block p-3 bg-green-50 rounded hover:bg-green-100">
            My Schedule →
          </Link>
        </div>
      </div>
    </div>
  )
}
