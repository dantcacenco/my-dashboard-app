import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalsList from './ProposalsList'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface ProposalData {
  id: string
  proposal_number: string
  title: string
  total: number
  status: string
  created_at: string
  updated_at: string
  customers: Customer[]
}

interface PageProps {
  searchParams: Promise<{
    status?: string
    startDate?: string
    endDate?: string
    search?: string
  }>
}

export default async function ProposalsPage({ searchParams }: PageProps) {
  const supabase = await createClient()

  const { data: { user }, error: userError } = await supabase.auth.getUser()
  
  if (userError || !user) {
    redirect('/auth/signin')
  }

  const params = await searchParams

  let query = supabase
    .from('proposals')
    .select('*, customers(*)')
    .order('created_at', { ascending: false })

  if (params.status && params.status !== 'all') {
    query = query.eq('status', params.status)
  }

  if (params.startDate) {
    const startDate = new Date(params.startDate)
    startDate.setHours(0, 0, 0, 0)
    query = query.gte('created_at', startDate.toISOString())
  }
  
  if (params.endDate) {
    const endDate = new Date(params.endDate)
    endDate.setHours(23, 59, 59, 999)
    query = query.lte('created_at', endDate.toISOString())
  }

  const { data: proposals, error } = await query

  if (error) {
    console.error('Error fetching proposals:', error)
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-gray-900 mb-4">Error Loading Proposals</h1>
            <p className="text-gray-600">Please try again later.</p>
          </div>
        </div>
      </div>
    )
  }

  let filteredProposals = proposals || []
  
  if (params.search) {
    const searchTerm = params.search.toLowerCase()
    filteredProposals = filteredProposals.filter(proposal => {
      const customer = proposal.customers?.[0]
      
      return proposal.proposal_number.toLowerCase().includes(searchTerm) ||
             proposal.title.toLowerCase().includes(searchTerm) ||
             (customer && customer.name.toLowerCase().includes(searchTerm)) ||
             (customer && customer.email.toLowerCase().includes(searchTerm))
    })
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <ProposalsList 
          proposals={filteredProposals} 
          searchParams={params}
        />
      </div>
    </div>
  )
}