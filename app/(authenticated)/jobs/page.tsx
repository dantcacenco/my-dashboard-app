import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-react'
import JobsTable from './JobsTable'

export default async function JobsPage({
  searchParams
}: {
  searchParams: Promise<{ page?: string }>
}) {
  const params = await searchParams
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

  // Pagination
  const page = parseInt(params?.page || '1')
  const pageSize = 10
  const from = (page - 1) * pageSize
  const to = from + pageSize - 1

  // Fetch jobs with related data
  const { data: jobs, error, count } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone
      ),
      profiles:technician_id (
        id,
        full_name,
        email
      )
    `, { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(from, to)

  // Debug logging
  console.log('Jobs page - fetched jobs:', jobs?.length || 0)
  console.log('Jobs page - error:', error)
  console.log('Jobs page - total count:', count)

  if (error) {
    console.error('Error fetching jobs:', error)
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Jobs</h1>
        <Link href="/jobs/new">
          <Button>
            <Plus className="h-4 w-4 mr-2" />
            New Job
          </Button>
        </Link>
      </div>

      <JobsTable 
        jobs={jobs || []} 
        totalCount={count || 0}
        currentPage={page}
        pageSize={pageSize}
      />
    </div>
  )
}
