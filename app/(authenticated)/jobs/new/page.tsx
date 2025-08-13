import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobCreationForm from './JobCreationForm'

export default async function NewJobPage({
  searchParams
}: {
  searchParams: Promise<{ proposal_id?: string }>
}) {
  const params = await searchParams
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/sign-in')
  }

  // Get user profile to check role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only boss/admin can create jobs
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/unauthorized')
  }

  // Get proposal data if proposal_id is provided
  let proposalData = null
  if (params.proposal_id) {
    const { data: proposal } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (*)
      `)
      .eq('id', params.proposal_id)
      .single()
    
    proposalData = proposal
  }

  // Get technicians for assignment
  const { data: technicians } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'technician')
    .order('full_name')

  // Get customers if no proposal
  const { data: customers } = await supabase
    .from('customers')
    .select('*')
    .order('name')

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Create New Job</h1>
          <p className="mt-2 text-gray-600">
            {proposalData ? 'Creating job from proposal' : 'Create a new job assignment'}
          </p>
        </div>
        
        <JobCreationForm 
          proposal={proposalData}
          technicians={technicians || []}
          customers={customers || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
