#!/bin/bash

echo "🔧 Fixing duplicate declaration error in CustomerProposalView.tsx..."

# Fix CustomerProposalView.tsx by replacing the entire file with corrected version
cat > app/proposal/view/\[token\]/CustomerProposalView.tsx << 'EOF'
'use client'

import { useState } from 'react'
import Image from 'next/image'
import { CheckCircleIcon, XCircleIcon, ClockIcon } from '@heroicons/react/24/solid'
import PaymentStages from '@/app/components/PaymentStages'

interface ProposalItem {
  id: string
  name: string
  description: string | null
  quantity: number
  unit_price: number
  total_price: number
  is_addon: boolean
  is_selected: boolean
}

interface CustomerProposalViewProps {
  proposal: any
  error?: 'not_found' | 'invalid_token' | null
}

export default function CustomerProposalView({ proposal, error }: CustomerProposalViewProps) {
  const [selectedAddons, setSelectedAddons] = useState<string[]>(
    proposal?.proposal_items?.filter((item: ProposalItem) => item.is_addon && item.is_selected).map((item: ProposalItem) => item.id) || []
  )
  const [customerName, setCustomerName] = useState('')
  const [customerNotes, setCustomerNotes] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Handle addon selection
  const handleAddonToggle = (addonId: string) => {
    setSelectedAddons(prev => 
      prev.includes(addonId) 
        ? prev.filter(id => id !== addonId)
        : [...prev, addonId]
    )
  }

  // Calculate total with selected addons
  const calculateTotal = () => {
    if (!proposal) return 0
    
    const baseTotal = proposal.proposal_items
      ?.filter((item: ProposalItem) => !item.is_addon)
      .reduce((sum: number, item: ProposalItem) => sum + item.total_price, 0) || 0

    const addonsTotal = proposal.proposal_items
      ?.filter((item: ProposalItem) => item.is_addon && selectedAddons.includes(item.id))
      .reduce((sum: number, item: ProposalItem) => sum + item.total_price, 0) || 0

    return baseTotal + addonsTotal
  }

  // Handle approval/rejection
  const handleDecision = async (approved: boolean) => {
    if (!customerName.trim() && approved) {
      alert('Please provide your name/signature for approval')
      return
    }

    setIsSubmitting(true)
    
    try {
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId: proposal.id,
          approved,
          customerName: customerName.trim(),
          selectedAddons,
          finalTotal: calculateTotal(),
          customerNotes: customerNotes.trim()
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to submit decision')
      }

      const data = await response.json()
      
      // Redirect based on decision
      if (approved) {
        // Redirect to payment page
        window.location.href = `/proposal/payment/${proposal.customer_view_token}`
      } else {
        // Show rejection confirmation
        alert('Thank you for your response. The proposal has been declined.')
        window.location.reload()
      }
    } catch (error) {
      console.error('Error submitting decision:', error)
      alert('An error occurred. Please try again.')
    } finally {
      setIsSubmitting(false)
    }
  }

  // Format currency
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  // Format date
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  // Show error page if there's an error
  if (error || !proposal) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <main className="flex-1">
            <div className="py-6">
              <div className="max-w-3xl mx-auto px-4 sm:px-6 md:px-8">
                <h1 className="text-2xl font-semibold text-gray-900">
                  {error === 'not_found' ? 'Proposal not found' : 'Invalid access'}
                </h1>
                <p className="mt-1 text-base text-gray-500">
                  {error === 'not_found' 
                    ? 'The proposal you are looking for does not exist or has been removed.'
                    : 'You do not have permission to view this proposal.'}
                </p>
              </div>
            </div>
          </main>
        </div>
      </div>
    )
  }

  const isApproved = proposal.status === 'approved' && proposal.approved_at
  const isRejected = proposal.status === 'rejected' && proposal.rejected_at
  const isPending = !isApproved && !isRejected

  // Show payment stages for approved proposals
  const showPaymentStages = isApproved && (
    !proposal.final_paid_at || // Not fully paid
    (proposal.deposit_paid_at || proposal.progress_paid_at || proposal.final_paid_at) // Or has any payments
  )

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="bg-white shadow-sm rounded-lg p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-2xl font-bold text-gray-900">
              Proposal #{proposal.proposal_number}
            </h1>
            <div className="flex items-center">
              {isApproved && (
                <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                  <CheckCircleIcon className="w-5 h-5 mr-1" />
                  Approved
                </span>
              )}
              {isRejected && (
                <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800">
                  <XCircleIcon className="w-5 h-5 mr-1" />
                  Rejected
                </span>
              )}
              {isPending && (
                <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800">
                  <ClockIcon className="w-5 h-5 mr-1" />
                  Pending Approval
                </span>
              )}
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Customer</p>
              <p className="font-medium">{proposal.customers.name}</p>
              <p className="text-sm text-gray-500">{proposal.customers.email}</p>
              <p className="text-sm text-gray-500">{proposal.customers.phone}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Valid Until</p>
              <p className="font-medium">
                {proposal.valid_until ? formatDate(proposal.valid_until) : 'No expiration'}
              </p>
            </div>
          </div>
        </div>

        {/* Payment Stages */}
        {showPaymentStages && (
          <PaymentStages proposal={proposal} />
        )}

        {/* Proposal Content */}
        <div className="bg-white shadow-sm rounded-lg p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">{proposal.title}</h2>
          {proposal.description && (
            <p className="text-gray-600 mb-6">{proposal.description}</p>
          )}

          {/* Items */}
          <div className="mb-6">
            <h3 className="text-md font-semibold text-gray-900 mb-3">Items & Services</h3>
            <div className="space-y-2">
              {proposal.proposal_items
                ?.filter((item: ProposalItem) => !item.is_addon)
                .map((item: ProposalItem) => (
                  <div key={item.id} className="flex justify-between py-2 border-b border-gray-100">
                    <div>
                      <p className="font-medium">{item.name}</p>
                      {item.description && (
                        <p className="text-sm text-gray-600">{item.description}</p>
                      )}
                      <p className="text-sm text-gray-500">
                        {item.quantity} × {formatCurrency(item.unit_price)}
                      </p>
                    </div>
                    <p className="font-medium">{formatCurrency(item.total_price)}</p>
                  </div>
                ))}
            </div>
          </div>

          {/* Add-ons */}
          {proposal.proposal_items?.some((item: ProposalItem) => item.is_addon) && (
            <div className="mb-6">
              <h3 className="text-md font-semibold text-gray-900 mb-3">Optional Add-ons</h3>
              <div className="space-y-2">
                {proposal.proposal_items
                  ?.filter((item: ProposalItem) => item.is_addon)
                  .map((item: ProposalItem) => (
                    <div key={item.id} className="flex items-center justify-between py-2 border-b border-gray-100">
                      <div className="flex items-center flex-1">
                        <input
                          type="checkbox"
                          id={item.id}
                          checked={selectedAddons.includes(item.id)}
                          onChange={() => handleAddonToggle(item.id)}
                          disabled={!isPending}
                          className="mr-3 h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <label htmlFor={item.id} className="flex-1 cursor-pointer">
                          <p className="font-medium">{item.name}</p>
                          {item.description && (
                            <p className="text-sm text-gray-600">{item.description}</p>
                          )}
                        </label>
                      </div>
                      <p className="font-medium ml-4">{formatCurrency(item.total_price)}</p>
                    </div>
                  ))}
              </div>
            </div>
          )}

          {/* Total */}
          <div className="border-t pt-4">
            <div className="flex justify-between text-lg font-semibold">
              <span>Total</span>
              <span>{formatCurrency(calculateTotal())}</span>
            </div>
          </div>
        </div>

        {/* Approval Section - Only show if pending */}
        {isPending && (
          <div className="bg-white shadow-sm rounded-lg p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Approval</h3>
            
            <div className="mb-4">
              <label htmlFor="customerName" className="block text-sm font-medium text-gray-700 mb-1">
                Your Name (Required for approval)
              </label>
              <input
                type="text"
                id="customerName"
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter your full name"
              />
            </div>

            <div className="mb-6">
              <label htmlFor="customerNotes" className="block text-sm font-medium text-gray-700 mb-1">
                Notes or Comments (Optional)
              </label>
              <textarea
                id="customerNotes"
                value={customerNotes}
                onChange={(e) => setCustomerNotes(e.target.value)}
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Any additional comments or special requests..."
              />
            </div>

            <div className="flex gap-4">
              <button
                onClick={() => handleDecision(true)}
                disabled={isSubmitting}
                className="flex-1 bg-green-600 text-white px-6 py-3 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 disabled:bg-gray-400"
              >
                {isSubmitting ? 'Processing...' : 'Approve & Continue to Payment'}
              </button>
              <button
                onClick={() => handleDecision(false)}
                disabled={isSubmitting}
                className="flex-1 bg-red-600 text-white px-6 py-3 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 disabled:bg-gray-400"
              >
                {isSubmitting ? 'Processing...' : 'Decline Proposal'}
              </button>
            </div>
          </div>
        )}

        {/* Status Messages */}
        {isApproved && !showPaymentStages && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-6">
            <div className="flex items-center">
              <CheckCircleIcon className="w-6 h-6 text-green-600 mr-2" />
              <div>
                <h3 className="font-semibold text-green-900">Proposal Approved</h3>
                <p className="text-green-700">
                  This proposal was approved on {formatDate(proposal.approved_at)}.
                  {proposal.signature_data && ` Signed by: ${proposal.signature_data}`}
                </p>
                {proposal.total_paid >= proposal.total && (
                  <p className="text-green-700 mt-1">Payment has been completed in full.</p>
                )}
              </div>
            </div>
          </div>
        )}

        {isRejected && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <div className="flex items-center">
              <XCircleIcon className="w-6 h-6 text-red-600 mr-2" />
              <div>
                <h3 className="font-semibold text-red-900">Proposal Declined</h3>
                <p className="text-red-700">
                  This proposal was declined on {formatDate(proposal.rejected_at)}.
                </p>
                {proposal.customer_notes && (
                  <p className="text-red-700 mt-2">Reason: {proposal.customer_notes}</p>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
EOF

# Commit the fix
git add .
git commit -m "fix: resolve duplicate declaration error in CustomerProposalView

- Remove duplicate showPaymentStages declaration
- Properly integrate PaymentStages component
- Ensure single declaration of all variables"

git push origin main

echo "✅ Fixed duplicate declaration error!"
echo ""
echo "The build should now pass. The CustomerProposalView.tsx file has been properly updated with:"
echo "- Single declaration of showPaymentStages"
echo "- Proper PaymentStages component integration"
echo "- Clean variable declarations"