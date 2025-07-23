import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalsList from './ProposalsList'

export default async function ProposalsPage() {
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile to check role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only boss can view proposals
  if (profile?.role !== 'boss') {
    redirect('/unauthorized')
  }

  // Get all proposals with customer data
  const { data: proposals, error: proposalsError } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone,
        address
      )
    `)
    .order('created_at', { ascending: false })

  if (proposalsError) {
    console.error('Error fetching proposals:', proposalsError)
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Proposals</h1>
              <p className="mt-2 text-gray-600">Manage your customer proposals and estimates</p>
            </div>
            <a
              href="/proposals/new"
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:ring-2 focus:ring-blue-500"
            >
              New Proposal
            </a>
          </div>
        </div>
        
        <ProposalsList proposals={proposals || []} />
      </div>
    </div>
  )
}