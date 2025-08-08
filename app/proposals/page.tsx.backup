import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalsList from '@/components/proposals/ProposalsList'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { Plus } from 'lucide-react'

export default async function ProposalsPage() {
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

  // Check if user has admin or boss role
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  // Fetch proposals with customer information
  const { data: proposals, error } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone
      )
    `)
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching proposals:', error)
  }

  return (
    <div className="p-6">
      <div className="mb-6 flex justify-between items-center">
        <h1 className="text-3xl font-bold">Proposals</h1>
        <Link href="/proposals/new">
          <Button>
            <Plus className="h-4 w-4 mr-2" />
            New Proposal
          </Button>
        </Link>
      </div>
      <ProposalsList 
        proposals={proposals || []} 
        userRole={profile?.role || 'boss'}
      />
    </div>
  )
}
