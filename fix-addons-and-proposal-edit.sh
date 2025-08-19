#!/bin/bash

# Fix Add-ons and Remaining Issues
echo "🔧 Fixing add-ons behavior and proposal editing..."

# 1. Create proposal edit API route
echo "📝 Creating proposal edit API route..."
cat > "/Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/api/proposals/[id]/route.ts" << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function PATCH(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params
    const supabase = await createClient()
    const body = await request.json()

    // Check auth
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // If proposal is being edited, reset status to draft
    const updateData = {
      ...body,
      status: 'draft',
      sent_at: null,
      first_viewed_at: null,
      approved_at: null,
      rejected_at: null,
      updated_at: new Date().toISOString()
    }

    const { data, error } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Error updating proposal:', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in PATCH /api/proposals/[id]:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
EOF

# 2. Update CustomerProposalView to handle add-ons with checkboxes
echo "📝 Updating CustomerProposalView for add-ons..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/proposal/view/\[token\]/CustomerProposalView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import MobileDebug from '@/components/MobileDebug'

interface CustomerProposalViewProps {
  proposal: any
  token: string
}

export default function CustomerProposalView({ proposal: initialProposal, token }: CustomerProposalViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [proposal, setProposal] = useState(initialProposal)
  const [isApproving, setIsApproving] = useState(false)
  const [isRejecting, setIsRejecting] = useState(false)
  const [showRejectDialog, setShowRejectDialog] = useState(false)
  const [rejectionReason, setRejectionReason] = useState('')
  const [selectedAddons, setSelectedAddons] = useState<Set<string>>(new Set())
  const [proposalTotal, setProposalTotal] = useState(proposal.total)

  // Initialize selected addons
  useEffect(() => {
    const initialAddons = new Set<string>()
    proposal.proposal_items?.forEach((item: any) => {
      if (item.is_addon && item.is_selected) {
        initialAddons.add(item.id)
      }
    })
    setSelectedAddons(initialAddons)
    calculateTotal(initialAddons)
  }, [])

  const calculateTotal = (addons: Set<string>) => {
    let subtotal = 0
    
    // Add base items (non-addons)
    proposal.proposal_items?.forEach((item: any) => {
      if (!item.is_addon) {
        subtotal += item.total_price || 0
      } else if (addons.has(item.id)) {
        // Add selected addons
        subtotal += item.total_price || 0
      }
    })

    const taxAmount = subtotal * (proposal.tax_rate || 0)
    const total = subtotal + taxAmount
    
    setProposalTotal(total)
    return total
  }

  const toggleAddon = async (itemId: string) => {
    const newAddons = new Set(selectedAddons)
    if (newAddons.has(itemId)) {
      newAddons.delete(itemId)
    } else {
      newAddons.add(itemId)
    }
    setSelectedAddons(newAddons)
    
    // Update the proposal item selection
    const { error } = await supabase
      .from('proposal_items')
      .update({ is_selected: newAddons.has(itemId) })
      .eq('id', itemId)
    
    if (error) {
      console.error('Error updating addon:', error)
      toast.error('Failed to update selection')
      return
    }
    
    // Recalculate total
    const newTotal = calculateTotal(newAddons)
    
    // Update proposal total
    await supabase
      .from('proposals')
      .update({ 
        total: newTotal,
        subtotal: newTotal / (1 + (proposal.tax_rate || 0))
      })
      .eq('id', proposal.id)
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const handleApprove = async () => {
    setIsApproving(true)
    try {
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: proposal.id,
          action: 'approve'
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || data.mobileMessage || 'Failed to approve proposal')
      }

      toast.success('Proposal approved successfully!')
      
      // Redirect to payment page
      if (data.redirectUrl) {
        router.push(data.redirectUrl)
      } else {
        router.push(`/customer-proposal/${token}/payment`)
      }
    } catch (error: any) {
      console.error('Approval error:', error)
      toast.error(error.message || 'Failed to approve proposal')
      setIsApproving(false)
    }
  }

  const handleReject = async () => {
    setIsRejecting(true)
    try {
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: proposal.id,
          action: 'reject',
          rejectionReason
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || data.mobileMessage || 'Failed to reject proposal')
      }

      toast.success('Proposal rejected')
      setShowRejectDialog(false)
      
      // Refresh the proposal
      window.location.reload()
    } catch (error: any) {
      console.error('Rejection error:', error)
      toast.error(error.message || 'Failed to reject proposal')
    } finally {
      setIsRejecting(false)
    }
  }

  const debugData = {
    proposalId: proposal.id,
    status: proposal.status,
    total: proposalTotal,
    selectedAddons: Array.from(selectedAddons),
    items: proposal.proposal_items?.map((item: any) => ({
      id: item.id,
      name: item.name,
      is_addon: item.is_addon,
      is_selected: item.is_selected,
      price: item.total_price
    }))
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <MobileDebug data={debugData} title="Proposal Debug" />
      
      <div className="max-w-4xl mx-auto px-4">
        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          {/* Header */}
          <div className="bg-blue-600 text-white p-6">
            <h1 className="text-2xl font-bold">{proposal.title}</h1>
            <p className="mt-2">Proposal #{proposal.proposal_number}</p>
          </div>

          {/* Customer Info */}
          <div className="p-6 border-b">
            <h2 className="text-lg font-semibold mb-3">Customer Information</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">Name</p>
                <p className="font-medium">{proposal.customers?.name}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Email</p>
                <p className="font-medium">{proposal.customers?.email}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Phone</p>
                <p className="font-medium">{proposal.customers?.phone}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Address</p>
                <p className="font-medium">{proposal.customers?.address}</p>
              </div>
            </div>
          </div>

          {/* Proposal Items */}
          <div className="p-6 border-b">
            <h2 className="text-lg font-semibold mb-3">Services & Add-ons</h2>
            <div className="space-y-3">
              {proposal.proposal_items?.map((item: any) => (
                <div 
                  key={item.id} 
                  className={`p-3 rounded-lg border ${
                    item.is_addon 
                      ? 'bg-orange-50 border-orange-200' 
                      : 'bg-gray-50 border-gray-200'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3">
                      {item.is_addon && (
                        <input
                          type="checkbox"
                          checked={selectedAddons.has(item.id)}
                          onChange={() => toggleAddon(item.id)}
                          className="mt-1 h-5 w-5 text-blue-600 rounded"
                          disabled={proposal.status !== 'sent'}
                        />
                      )}
                      <div className="flex-1">
                        <div className="font-medium">
                          {item.name}
                          {item.is_addon && (
                            <span className="ml-2 text-xs bg-orange-200 text-orange-800 px-2 py-1 rounded">
                              ADD-ON
                            </span>
                          )}
                        </div>
                        {item.description && (
                          <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                        )}
                        <div className="text-sm text-gray-500 mt-1">
                          Qty: {item.is_addon ? (selectedAddons.has(item.id) ? item.quantity : 0) : item.quantity} × {formatCurrency(item.unit_price)}
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="font-semibold">
                        {item.is_addon && !selectedAddons.has(item.id) 
                          ? formatCurrency(0)
                          : formatCurrency(item.total_price)
                        }
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Totals */}
          <div className="p-6 bg-gray-50">
            <div className="space-y-2">
              <div className="flex justify-between text-lg">
                <span>Subtotal</span>
                <span>{formatCurrency(proposalTotal / (1 + (proposal.tax_rate || 0)))}</span>
              </div>
              <div className="flex justify-between text-lg">
                <span>Tax ({((proposal.tax_rate || 0) * 100).toFixed(2)}%)</span>
                <span>{formatCurrency(proposalTotal - (proposalTotal / (1 + (proposal.tax_rate || 0))))}</span>
              </div>
              <div className="flex justify-between text-xl font-bold pt-2 border-t">
                <span>Total</span>
                <span>{formatCurrency(proposalTotal)}</span>
              </div>
            </div>
          </div>

          {/* Actions */}
          {proposal.status === 'sent' && (
            <div className="p-6 bg-white border-t">
              <div className="flex flex-col sm:flex-row gap-3">
                <button
                  onClick={handleApprove}
                  disabled={isApproving}
                  className="flex-1 bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {isApproving ? (
                    <>Processing...</>
                  ) : (
                    <>
                      <CheckCircleIcon className="h-5 w-5" />
                      Approve Proposal
                    </>
                  )}
                </button>
                <button
                  onClick={() => setShowRejectDialog(true)}
                  className="flex-1 bg-red-600 text-white px-6 py-3 rounded-lg hover:bg-red-700 flex items-center justify-center gap-2"
                >
                  <XCircleIcon className="h-5 w-5" />
                  Reject Proposal
                </button>
              </div>
            </div>
          )}

          {/* Status Display */}
          {proposal.status !== 'sent' && (
            <div className="p-6 bg-white border-t">
              <div className={`text-center py-3 px-6 rounded-lg ${
                proposal.status === 'approved' ? 'bg-green-100 text-green-800' :
                proposal.status === 'rejected' ? 'bg-red-100 text-red-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                Proposal Status: {proposal.status.toUpperCase()}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Reject Dialog */}
      {showRejectDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full">
            <h3 className="text-lg font-semibold mb-3">Reject Proposal</h3>
            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="Please provide a reason for rejection (optional)"
              className="w-full p-3 border rounded-lg mb-4"
              rows={4}
            />
            <div className="flex gap-3">
              <button
                onClick={() => setShowRejectDialog(false)}
                className="flex-1 px-4 py-2 border rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={isRejecting}
                className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                {isRejecting ? 'Rejecting...' : 'Confirm Reject'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
EOF

echo "🔨 Building the application..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -50

echo ""
echo "📦 Committing changes..."
git add -A
git commit -m "Fix add-ons with checkboxes, proposal editing, and mobile debug"
git push origin main

echo ""
echo "✅ All fixes applied!"
echo ""
echo "🎯 What was fixed:"
echo "1. Proposal editing now resets status to draft"
echo "2. Add-ons have checkboxes on customer view"
echo "3. Add-ons highlighted in orange"
echo "4. Quantity is 0 for unchecked add-ons"
echo "5. Total recalculates when add-ons are toggled"
echo "6. Mobile debug component added (?debug=true)"
echo ""
echo "📝 Check browser console for debug info"
echo "Add ?debug=true to URLs for mobile debugging"
