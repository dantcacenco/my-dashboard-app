import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalBuilder from './ProposalBuilder'

export default async function NewProposalPage() {
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE: 'profiles' with 'id' column
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Allow both admin and boss roles to create proposals
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  // Get customers and pricing items
  const [customersResult, pricingResult] = await Promise.all([
    supabase
      .from('customers')
      .select('*')
      .order('name'),
    supabase
      .from('pricing_items')
      .select('*')
      .eq('is_active', true)
      .order('category, name')
  ])

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Create New Proposal</h1>
          <p className="mt-2 text-gray-600">Build a professional proposal for your customer</p>
        </div>
        
        <ProposalBuilder 
          customers={customersResult.data || []}
          pricingItems={pricingResult.data || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
