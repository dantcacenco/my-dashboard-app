'use client'

import { useState, useCallback, useEffect } from 'react'
import Image from 'next/image'
import { CheckCircleIcon, XCircleIcon, ClockIcon } from '@heroicons/react/24/solid'
import { createClient } from '@/lib/supabase/client'
import { useSearchParams } from 'next/navigation'
import MultiStagePayment from '@/components/MultiStagePayment'

interface ProposalItem {
  id: string
  name: string
  description: string
  quantity: number
  unit_price: number
  total_price: number
  is_addon: boolean
  is_selected: boolean
}

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface Proposal {
  id: string
  proposal_number: string
  customer_id: string
  title: string
  description: string
  subtotal: number
  tax_rate: number
  tax_amount: number
  total: number
  status: string
  valid_until: string | null
  signed_at: string | null
  signature_data: string | null
  created_at: string
  customer_view_token: string
  approved_at: string | null
  rejected_at: string | null
  first_viewed_at: string | null
  customer_notes: string | null
  customers: Customer
  proposal_items: ProposalItem[]
  payment_status: string | null
  payment_method: string | null
  deposit_paid_at: string | null
  deposit_amount: number | null
  progress_paid_at: string | null
  progress_payment_amount: number | null
  final_paid_at: string | null
  final_payment_amount: number | null
  total_paid: number | null
  current_payment_stage: string | null
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount)
}

function formatDate(dateString: string): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date(dateString))
}

export default function CustomerProposalView({ 
  proposal: initialProposal,
  error 
}: { 
  proposal: Proposal
  error?: string 
}) {
  const [proposal, setProposal] = useState<Proposal>(initialProposal)
  const [isApproving, setIsApproving] = useState(false)
  const [isRejecting, setIsRejecting] = useState(false)
  const [showRejectionForm, setShowRejectionForm] = useState(false)
  const [customerNotes, setCustomerNotes] = useState('')
  const [customerName, setCustomerName] = useState('')
  const searchParams = useSearchParams()
  const supabase = createClient()

  // Check for payment success/failure messages
  useEffect(() => {
    const payment = searchParams.get('payment')
    const stage = searchParams.get('stage')
    
    if (payment === 'success' && stage) {
      const stageLabel = stage === 'roughin' ? 'Rough In' : stage.charAt(0).toUpperCase() + stage.slice(1)
      alert(`✅ ${stageLabel} payment completed successfully!`)
      // Refresh proposal data
      refreshProposal()
    } else if (payment === 'cancelled') {
      alert('Payment was cancelled. You can try again when ready.')
    } else if (payment === 'error') {
      alert('There was an error processing your payment. Please try again.')
    }
  }, [searchParams])

  const refreshProposal = async () => {
    const { data, error } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (id, name, email, phone, address),
        proposal_items (*)
      `)
      .eq('id', proposal.id)
      .single()

    if (data && !error) {
      setProposal(data)
    }
  }

  const handleApproval = async () => {
    if (!customerName.trim()) {
      alert('Please enter your name to approve the proposal')
      return
    }

    setIsApproving(true)
    
    try {
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId: proposal.id,
          approved: true,
          customerNotes: customerNotes.trim(),
          customerName: customerName.trim()
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to approve proposal')
      }

      const { proposal: updatedProposal } = await response.json()
      setProposal(updatedProposal)
      alert('Proposal approved successfully! You can now proceed with payment.')
      
    } catch (error) {
      console.error('Error approving proposal:', error)
      alert('Failed to approve proposal. Please try again.')
    } finally {
      setIsApproving(false)
    }
  }

  const handleRejection = async () => {
    if (!customerNotes.trim()) {
      alert('Please provide a reason for rejection')
      return
    }

    setIsRejecting(true)
    
    try {
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId: proposal.id,
          approved: false,
          customerNotes: customerNotes.trim(),
          customerName: customerName.trim() || proposal.customers.name
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to reject proposal')
      }

      const { proposal: updatedProposal } = await response.json()
      setProposal(updatedProposal)
      setShowRejectionForm(false)
      
    } catch (error) {
      console.error('Error rejecting proposal:', error)
      alert('Failed to reject proposal. Please try again.')
    } finally {
      setIsRejecting(false)
    }
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 px-4 py-16 sm:px-6 sm:py-24 md:grid md:place-items-center lg:px-8">
        <div className="max-w-max mx-auto">
          <main className="sm:flex">
            <XCircleIcon className="h-12 w-12 text-red-500" />
            <div className="sm:ml-6">
              <div className="sm:border-l sm:border-gray-200 sm:pl-6">
                <h1 className="text-4xl font-extrabold text-gray-900 tracking-tight sm:text-5xl">
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

  const isApproved = proposal.status === 'approved'
  const isRejected = proposal.status === 'rejected'
  const isPending = !isApproved && !isRejected

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm mb-6 p-6">
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-3xl font-bold text-gray-900">
              Proposal #{proposal.proposal_number}
            </h1>
            <div className="flex items-center gap-2">
              {isApproved && (
                <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                  <CheckCircleIcon className="w-4 h-4 mr-1" />
                  Approved
                </span>
              )}
              {isRejected && (
                <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800">
                  <XCircleIcon className="w-4 h-4 mr-1" />
                  Rejected
                </span>
              )}
              {isPending && (
                <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800">
                  <ClockIcon className="w-4 h-4 mr-1" />
                  Pending Approval
                </span>
              )}
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-gray-600">Customer</p>
              <p className="font-medium">{proposal.customers.name}</p>
            </div>
            <div>
              <p className="text-gray-600">Date</p>
              <p className="font-medium">{formatDate(proposal.created_at)}</p>
            </div>
            {proposal.valid_until && (
              <div>
                <p className="text-gray-600">Valid Until</p>
                <p className="font-medium">{formatDate(proposal.valid_until)}</p>
              </div>
            )}
          </div>
        </div>

        {/* Proposal Details */}
        <div className="bg-white rounded-lg shadow-sm mb-6 p-6">
          <h2 className="text-xl font-semibold mb-4">{proposal.title}</h2>
          {proposal.description && (
            <p className="text-gray-600 whitespace-pre-wrap">{proposal.description}</p>
          )}
        </div>

        {/* Line Items */}
        <div className="bg-white rounded-lg shadow-sm mb-6 p-6">
          <h3 className="text-lg font-semibold mb-4">Services & Materials</h3>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3">Item</th>
                  <th className="text-center py-3">Qty</th>
                  <th className="text-right py-3">Unit Price</th>
                  <th className="text-right py-3">Total</th>
                </tr>
              </thead>
              <tbody>
                {proposal.proposal_items?.map((item) => (
                  <tr key={item.id} className="border-b">
                    <td className="py-3">
                      <div>
                        <p className="font-medium">{item.name}</p>
                        {item.description && (
                          <p className="text-sm text-gray-600">{item.description}</p>
                        )}
                      </div>
                    </td>
                    <td className="text-center py-3">{item.quantity}</td>
                    <td className="text-right py-3">{formatCurrency(item.unit_price)}</td>
                    <td className="text-right py-3">{formatCurrency(item.total_price)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr>
                  <td colSpan={3} className="text-right py-3 font-medium">Subtotal:</td>
                  <td className="text-right py-3">{formatCurrency(proposal.subtotal)}</td>
                </tr>
                <tr>
                  <td colSpan={3} className="text-right py-3 font-medium">
                    Tax ({proposal.tax_rate}%):
                  </td>
                  <td className="text-right py-3">{formatCurrency(proposal.tax_amount)}</td>
                </tr>
                <tr className="border-t">
                  <td colSpan={3} className="text-right py-3 text-xl font-bold">Total:</td>
                  <td className="text-right py-3 text-xl font-bold text-green-600">
                    {formatCurrency(proposal.total)}
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>

        {/* Approval/Rejection Section - Only show if pending */}
        {isPending && (
          <div className="bg-white rounded-lg shadow-sm mb-6 p-6">
            <h3 className="text-lg font-semibold mb-4">Approve or Reject Proposal</h3>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Your Name *
              </label>
              <input
                type="text"
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                placeholder="Enter your full name"
                className="w-full p-2 border rounded-md"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Notes (Optional)
              </label>
              <textarea
                value={customerNotes}
                onChange={(e) => setCustomerNotes(e.target.value)}
                placeholder="Any additional comments or requests..."
                className="w-full p-2 border rounded-md"
                rows={3}
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={handleApproval}
                disabled={isApproving || !customerName.trim()}
                className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isApproving ? 'Approving...' : 'Approve Proposal'}
              </button>
              
              <button
                onClick={() => setShowRejectionForm(true)}
                disabled={isRejecting}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                Reject
              </button>
            </div>
          </div>
        )}

        {/* Payment Section - Show only if approved */}
        {isApproved && (
          <MultiStagePayment
            proposalId={proposal.id}
            proposalNumber={proposal.proposal_number}
            customerName={proposal.customers.name}
            customerEmail={proposal.customers.email}
            totalAmount={proposal.total}
            depositAmount={proposal.deposit_amount || undefined}
            progressAmount={proposal.progress_payment_amount || undefined}
            finalAmount={proposal.final_payment_amount || undefined}
            depositPaidAt={proposal.deposit_paid_at || undefined}
            progressPaidAt={proposal.progress_paid_at || undefined}
            finalPaidAt={proposal.final_paid_at || undefined}
            onPaymentInitiated={() => {
              // Optional: Show loading state
            }}
          />
        )}

        {/* Rejection Notes - Show if rejected */}
        {isRejected && proposal.customer_notes && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-red-900 mb-2">Rejection Reason</h3>
            <p className="text-red-700">{proposal.customer_notes}</p>
          </div>
        )}

        {/* Rejection Modal */}
        {showRejectionForm && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
              <h3 className="text-lg font-semibold mb-4">Reject Proposal</h3>
              
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Reason for rejection *
                </label>
                <textarea
                  value={customerNotes}
                  onChange={(e) => setCustomerNotes(e.target.value)}
                  placeholder="Please provide a reason..."
                  className="w-full p-2 border rounded-md"
                  rows={4}
                />
              </div>

              <div className="flex gap-3">
                <button
                  onClick={() => setShowRejectionForm(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleRejection}
                  disabled={isRejecting || !customerNotes.trim()}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
                >
                  {isRejecting ? 'Rejecting...' : 'Confirm Rejection'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
