#!/bin/bash

set -e

echo "🔧 Creating comprehensive debug version..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Create a debug page that shows EVERYTHING
cat > app/\(authenticated\)/proposals/\[id\]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import ProposalView from './ProposalView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()
  
  // Debug object to collect all information
  const debug = {
    proposalId: id,
    steps: [] as string[],
    errors: [] as any[],
    data: {} as any
  }

  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return notFound()
  }
  
  debug.steps.push(`User authenticated: ${user.id}`)

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()
    
  debug.steps.push(`Profile loaded: role=${profile?.role}`)

  // STEP 1: First try to get just the proposal without joins
  const { data: proposalBasic, error: basicError } = await supabase
    .from('proposals')
    .select('*')
    .eq('id', id)
    .single()
    
  if (basicError) {
    debug.errors.push({ step: 'basic_proposal', error: basicError })
  } else {
    debug.data.proposalBasic = proposalBasic
    debug.steps.push('Basic proposal loaded successfully')
  }

  // STEP 2: Try to get proposal_items separately
  const { data: items, error: itemsError } = await supabase
    .from('proposal_items')
    .select('*')
    .eq('proposal_id', id)
    .order('sort_order')
    
  if (itemsError) {
    debug.errors.push({ step: 'proposal_items', error: itemsError })
  } else {
    debug.data.itemsCount = items?.length || 0
    debug.data.items = items
    debug.steps.push(`Loaded ${items?.length || 0} proposal items`)
  }

  // STEP 3: Try to get customer separately
  let customer = null
  if (proposalBasic?.customer_id) {
    const { data: customerData, error: customerError } = await supabase
      .from('customers')
      .select('*')
      .eq('id', proposalBasic.customer_id)
      .single()
      
    if (customerError) {
      debug.errors.push({ step: 'customer', error: customerError })
    } else {
      customer = customerData
      debug.steps.push('Customer loaded successfully')
    }
  }

  // STEP 4: Try the full join query
  const { data: proposalFull, error: fullError } = await supabase
    .from('proposals')
    .select(`
      *,
      customers!customer_id (
        id,
        name,
        email,
        phone,
        address
      ),
      proposal_items (
        *
      )
    `)
    .eq('id', id)
    .single()

  if (fullError) {
    debug.errors.push({ step: 'full_join', error: fullError })
    
    // If full join fails, show debug info
    return (
      <div className="p-6 max-w-6xl mx-auto">
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
          <h2 className="text-yellow-800 font-semibold text-xl mb-4">Debug Information</h2>
          
          <div className="space-y-4">
            <div>
              <h3 className="font-semibold text-yellow-700">Steps Completed:</h3>
              <ul className="list-disc pl-5 text-sm">
                {debug.steps.map((step, i) => (
                  <li key={i}>{step}</li>
                ))}
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold text-yellow-700">Errors:</h3>
              {debug.errors.map((err, i) => (
                <div key={i} className="bg-red-50 p-2 rounded mt-2">
                  <p className="text-sm font-medium">Step: {err.step}</p>
                  <p className="text-sm text-red-600">{err.error.message}</p>
                  <details className="text-xs text-gray-600 mt-1">
                    <summary>Full error</summary>
                    <pre>{JSON.stringify(err.error, null, 2)}</pre>
                  </details>
                </div>
              ))}
            </div>
            
            <div>
              <h3 className="font-semibold text-yellow-700">Data Collected:</h3>
              <details className="text-sm">
                <summary>Basic Proposal</summary>
                <pre className="bg-gray-50 p-2 rounded overflow-x-auto">
                  {JSON.stringify(debug.data.proposalBasic, null, 2)}
                </pre>
              </details>
              
              <details className="text-sm mt-2">
                <summary>Proposal Items ({debug.data.itemsCount || 0})</summary>
                <pre className="bg-gray-50 p-2 rounded overflow-x-auto">
                  {JSON.stringify(debug.data.items, null, 2)}
                </pre>
              </details>
            </div>
          </div>
        </div>

        {/* Try to show proposal even with separate data */}
        {proposalBasic && items && (
          <div className="mt-6">
            <h2 className="text-lg font-semibold mb-4">Attempting to display with separate queries:</h2>
            <ProposalView 
              proposal={{
                ...proposalBasic,
                customers: customer,
                proposal_items: items?.map(item => ({
                  ...item,
                  title: item.name,
                  item_type: item.is_addon ? 'add_on' : 'service'
                }))
              }}
              userRole={profile?.role || 'viewer'}
            />
          </div>
        )}
      </div>
    )
  }

  // If we get here, the full join worked
  debug.steps.push('Full join query successful')
  
  // Transform the data
  if (proposalFull.proposal_items) {
    proposalFull.proposal_items = proposalFull.proposal_items.map((item: any) => ({
      ...item,
      title: item.name,
      item_type: item.is_addon ? 'add_on' : 'service'
    }))
  }

  // Show success with debug option
  if (typeof window !== 'undefined' && window.location.search.includes('debug=true')) {
    return (
      <div className="p-6">
        <details className="mb-4 bg-green-50 p-4 rounded">
          <summary className="cursor-pointer font-semibold text-green-800">Debug: Success!</summary>
          <pre className="text-xs mt-2">{JSON.stringify(debug, null, 2)}</pre>
        </details>
        <ProposalView proposal={proposalFull} userRole={profile?.role || 'viewer'} />
      </div>
    )
  }

  return <ProposalView proposal={proposalFull} userRole={profile?.role || 'viewer'} />
}
EOF

echo "✅ Created comprehensive debug version"

# Commit and push
git add -A
git commit -m "Add comprehensive debugging for proposal display

- Try queries step by step to isolate the issue
- Show exactly which query fails and why
- Display all collected data for debugging
- Attempt to show proposal even if joins fail
- Add ?debug=true option for production debugging"

git push origin main

echo "✅ Debug version deployed!"
echo ""
echo "📋 What this does:"
echo "1. Tries basic proposal fetch (no joins)"
echo "2. Tries proposal_items separately"
echo "3. Tries customer separately"
echo "4. Tries full join query"
echo "5. Shows exactly where it fails with full error details"
echo "6. Shows all data that WAS successfully fetched"
echo "7. Attempts to display proposal with separate queries if join fails"
echo ""
echo "Add ?debug=true to URL for extra debug info even on success"
