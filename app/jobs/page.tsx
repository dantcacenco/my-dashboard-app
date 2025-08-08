import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobsList from './JobsList'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { Plus } from 'lucide-react'

export default async function JobsPage() {
  const supabase = await createClient()
  
  // Check authentication
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/sign-in')
  }

  // Get user profile to check role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only show jobs based on role
  let jobsQuery = supabase
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
      assigned_technician:profiles!jobs_assigned_technician_id_fkey (
        id,
        full_name,
        email
      )
    `)
    .order('created_at', { ascending: false })

  // Technicians only see their assigned jobs
  if (profile?.role === 'technician') {
    jobsQuery = jobsQuery.eq('assigned_technician_id', user.id)
  }

  const { data: jobs, error } = await jobsQuery

  if (error) {
    console.error('Error fetching jobs:', error)
  }

  return (
    <div className="p-6">
      <div className="mb-6 flex justify-between items-center">
        <h1 className="text-3xl font-bold">Jobs</h1>
        {(profile?.role === 'admin' || profile?.role === 'boss') && (
          <Link href="/jobs/new">
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              New Job
            </Button>
          </Link>
        )}
      </div>
      <JobsList 
        jobs={jobs || []} 
        userRole={profile?.role || 'technician'}
        userId={user.id}
      />
    </div>
  )
}
