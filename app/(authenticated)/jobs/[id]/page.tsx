import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobDetailView from './JobDetailView'
import JobDiagnostic from './diagnostic'

export default async function JobDetailPage({ 
  params,
  searchParams 
}: { 
  params: Promise<{ id: string }>
  searchParams: Promise<{ debug?: string }>
}) {
  const { id } = await params
  const { debug } = await searchParams
  
  // Show diagnostic if ?debug=true
  if (debug === 'true') {
    return <JobDiagnostic />
  }
  
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()
  
  const userRole = profile?.role || 'technician'

  // Fetch job with customer info and technician data
  const { data: job, error } = await supabase
    .from('jobs')
    .select(`
      *,
      customers!customer_id (
        name,
        email,
        phone,
        address
      )
    `)
    .eq('id', id)
    .single()
  
  // If job has technician_id, fetch technician info
  if (job && job.technician_id) {
    const { data: technician } = await supabase
      .from('profiles')
      .select('id, full_name, email, role')
      .eq('id', job.technician_id)
      .single()
    
    if (technician) {
      job.profiles = technician
    }
  }

  // If job has a proposal_id, fetch it separately
  if (job && job.proposal_id) {
    const { data: proposal } = await supabase
      .from('proposals')
      .select('proposal_number, title, total')
      .eq('id', job.proposal_id)
      .single()
    
    if (proposal) {
      job.proposals = [proposal]
    }
  }

  if (error || !job) {
    return (
      <div className="p-8 max-w-2xl mx-auto">
        <h1 className="text-2xl font-bold mb-4 text-red-600">Job Not Found</h1>
        <div className="bg-red-50 p-4 rounded-lg">
          <p className="mb-2">Job ID: <code>{id}</code></p>
          <p className="mb-2">Error: {error?.message || 'Job does not exist'}</p>
          <p className="text-sm text-gray-600 mt-4">
            Try adding <code>?debug=true</code> to the URL for diagnostic info
          </p>
          <a 
            href={`/jobs/${id}?debug=true`}
            className="inline-block mt-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Run Diagnostic
          </a>
        </div>
      </div>
    )
  }

  return <JobDetailView job={job} userRole={userRole} userId={user.id} />
}
