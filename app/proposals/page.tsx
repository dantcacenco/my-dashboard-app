import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalsList from './ProposalsList'

export default async function ProposalsPage({
  searchParams
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>
}) {
  const params = await searchParams
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  
  if (authError || !user) {
    redirect('/auth/signin')
  }

  // Get user profile to check role
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Allow both boss and admin roles
  if (!profile || (profile.role !== 'admin' && profile.role !== 'boss')) {
    console.error('User role:', profile?.role, '- redirecting to dashboard')
    redirect('/')
  }

  // Get proposals with customer data
  const { data: proposals, error } = await supabase
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

  if (error) {
    console.error('Error fetching proposals:', error)
  }

  // Process search params
  const status = typeof params.status === 'string' ? params.status : 'all'
  const startDate = typeof params.startDate === 'string' ? params.startDate : undefined
  const endDate = typeof params.endDate === 'string' ? params.endDate : undefined
  const search = typeof params.search === 'string' ? params.search : undefined

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <ProposalsList 
          proposals={proposals || []}
          searchParams={{
            status,
            startDate,
            endDate,
            search
          }}
        />
      </div>
    </div>
  )
}
