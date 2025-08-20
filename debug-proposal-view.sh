#!/bin/bash

set -e

echo "🔧 Adding debug logging to ProposalView to diagnose issue..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update ProposalView to add debugging
cat > app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { ArrowLeft, Edit, Send, FileText, DollarSign, Calendar, User, Clock } from 'lucide-react'
import Link from 'next/link'
import CreateJobModal from './CreateJobModal'

interface ProposalViewProps {
  proposal: any
  userRole: string
}

export default function ProposalView({ proposal, userRole }: ProposalViewProps) {
  const router = useRouter()
  const [showCreateJobModal, setShowCreateJobModal] = useState(false)

  // Debug logging
  console.log('ProposalView Debug:', {
    proposal_id: proposal.id,
    proposal_items: proposal.proposal_items,
    items_count: proposal.proposal_items?.length || 0,
    first_item: proposal.proposal_items?.[0]
  })

  const handleEdit = () => {
    router.push(`/proposals/${proposal.id}/edit`)
  }

  const handleSendProposal = () => {
    router.push(`/proposals/${proposal.id}/send`)
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'accepted': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  // If no items, show a message
  if (!proposal.proposal_items || proposal.proposal_items.length === 0) {
    console.log('No proposal_items found!')
  }

  // Separate services and add-ons
  const services = proposal.proposal_items?.filter((item: any) => item.item_type === 'service') || []
  const addOns = proposal.proposal_items?.filter((item: any) => item.item_type === 'add_on') || []
  
  console.log('Filtered items:', {
    services: services.length,
    addOns: addOns.length,
    services_data: services,
    addOns_data: addOns
  })
  
  const servicesSubtotal = services.reduce((sum: number, item: any) => sum + (item.total_price || 0), 0)
  const addOnsSubtotal = addOns.reduce((sum: number, item: any) => sum + (item.total_price || 0), 0)
  const subtotal = servicesSubtotal + addOnsSubtotal
  const taxRate = proposal.tax_rate || 0.08
  const tax = subtotal * taxRate
  const total = subtotal + tax

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-4">
          <Link href="/proposals">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Proposals
            </Button>
          </Link>
          <h1 className="text-2xl font-bold">Proposal {proposal.proposal_number}</h1>
          <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(proposal.status)}`}>
            {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
          </span>
        </div>
        
        <div className="flex gap-2">
          {proposal.status === 'draft' && (
            <>
              <Button onClick={handleEdit} variant="outline">
                <Edit className="h-4 w-4 mr-2" />
                Edit
              </Button>
              <Button onClick={handleSendProposal}>
                <Send className="h-4 w-4 mr-2" />
                Send Proposal
              </Button>
            </>
          )}
          {proposal.status === 'sent' && userRole === 'boss' && (
            <Button onClick={() => setShowCreateJobModal(true)} variant="default">
              <FileText className="h-4 w-4 mr-2" />
              Create Job
            </Button>
          )}
          {proposal.status === 'accepted' && !proposal.job_created && (
            <Button onClick={() => setShowCreateJobModal(true)} variant="default">
              <FileText className="h-4 w-4 mr-2" />
              Create Job
            </Button>
          )}
        </div>
      </div>

      {/* Proposal Info */}
      <div className="bg-white rounded-lg shadow-sm border p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4">{proposal.title}</h2>
        {proposal.description && (
          <p className="text-gray-600 mb-6">{proposal.description}</p>
        )}
        
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div className="flex items-center gap-2">
            <User className="h-4 w-4 text-gray-500" />
            <span className="text-gray-500">Customer:</span>
            <span className="font-medium">{proposal.customers?.name || proposal.customer_name}</span>
          </div>
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-gray-500" />
            <span className="text-gray-500">Created:</span>
            <span className="font-medium">{new Date(proposal.created_at).toLocaleDateString()}</span>
          </div>
        </div>
      </div>

      {/* Items Section - Always show, even if empty for debugging */}
      <div className="bg-white rounded-lg shadow-sm border p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4">Items</h2>
        
        {(!proposal.proposal_items || proposal.proposal_items.length === 0) ? (
          <p className="text-gray-500">No items found. Check console for debug info.</p>
        ) : (
          <>
            {/* Show all items for debugging */}
            <div className="mb-6">
              <h3 className="font-medium text-gray-700 mb-3">All Items (Debug):</h3>
              <div className="space-y-2">
                {proposal.proposal_items.map((item: any, index: number) => (
                  <div key={item.id || index} className="p-2 bg-yellow-50 border rounded text-xs">
                    <pre>{JSON.stringify(item, null, 2)}</pre>
                  </div>
                ))}
              </div>
            </div>

            {/* Services */}
            {services.length > 0 && (
              <div className="mb-6">
                <h3 className="font-medium text-gray-700 mb-3">Services & Materials:</h3>
                <div className="space-y-2">
                  {services.map((item: any) => (
                    <div key={item.id} className="flex justify-between items-center p-3 bg-gray-50 rounded">
                      <div>
                        <div className="font-medium">{item.title}</div>
                        {item.description && (
                          <div className="text-sm text-gray-600">{item.description}</div>
                        )}
                        <div className="text-sm text-gray-500">
                          Qty: {item.quantity} @ ${item.unit_price?.toFixed(2) || '0.00'}
                        </div>
                      </div>
                      <div className="font-semibold">${item.total_price?.toFixed(2) || '0.00'}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Add-ons */}
            {addOns.length > 0 && (
              <div className="mb-6">
                <h3 className="font-medium text-gray-700 mb-3">Add-ons:</h3>
                <div className="space-y-2">
                  {addOns.map((item: any) => (
                    <div key={item.id} className="flex justify-between items-center p-3 bg-orange-50 border border-orange-200 rounded">
                      <div>
                        <div className="font-medium flex items-center gap-2">
                          {item.title}
                          <span className="text-xs bg-orange-200 text-orange-800 px-2 py-0.5 rounded">Add-on</span>
                        </div>
                        {item.description && (
                          <div className="text-sm text-gray-600">{item.description}</div>
                        )}
                        <div className="text-sm text-gray-500">
                          Qty: {item.quantity} @ ${item.unit_price?.toFixed(2) || '0.00'}
                        </div>
                      </div>
                      <div className="font-semibold">${item.total_price?.toFixed(2) || '0.00'}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </>
        )}

        {/* Totals */}
        <div className="border-t pt-4 space-y-2">
          {services.length > 0 && (
            <div className="flex justify-between text-sm">
              <span>Services Subtotal:</span>
              <span>${servicesSubtotal.toFixed(2)}</span>
            </div>
          )}
          {addOns.length > 0 && (
            <div className="flex justify-between text-sm">
              <span>Add-ons Subtotal:</span>
              <span>${addOnsSubtotal.toFixed(2)}</span>
            </div>
          )}
          <div className="flex justify-between">
            <span>Subtotal:</span>
            <span>${subtotal.toFixed(2)}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span>Tax ({(taxRate * 100).toFixed(1)}%):</span>
            <span>${tax.toFixed(2)}</span>
          </div>
          <div className="flex justify-between text-lg font-bold pt-2 border-t">
            <span>Total:</span>
            <span className="text-green-600">${total.toFixed(2)}</span>
          </div>
        </div>
      </div>

      {/* Payment Terms */}
      {proposal.payment_stages && proposal.payment_stages.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border p-6">
          <h2 className="text-xl font-semibold mb-4">Payment Terms</h2>
          <div className="space-y-3">
            {proposal.payment_stages.map((stage: any, index: number) => (
              <div key={stage.id || index} className="flex justify-between items-center p-3 bg-gray-50 rounded">
                <div>
                  <span className="font-medium">{stage.stage_name}</span>
                  <span className="text-sm text-gray-500 ml-2">({stage.percentage}%)</span>
                </div>
                <span className="font-semibold">${stage.amount?.toFixed(2) || '0.00'}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Create Job Modal */}
      {showCreateJobModal && (
        <CreateJobModal
          onClose={() => setShowCreateJobModal(false)}
          proposal={proposal}
        />
      )}
    </div>
  )
}
EOF

echo "✅ Updated ProposalView with extensive debugging"

# Clean up and commit
rm -f app/\(authenticated\)/proposals/\[id\]/page.tsx.backup

git add -A
git commit -m "Add debug logging to ProposalView to diagnose items issue

- Added extensive console logging
- Shows raw item data in debug section
- Helps identify if items are missing or have wrong structure"

git push origin main

echo "✅ Debug version deployed. Check browser console for detailed info."
echo ""
echo "📋 Chat Status: ~75% used, 25% remaining"
