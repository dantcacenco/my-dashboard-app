'use client'

import { useState, useCallback, useEffect } from 'react'
import Image from 'next/image'
import { CheckCircleIcon, XCircleIcon, ClockIcon, LockClosedIcon } from '@heroicons/react/24/solid'
import { createClient } from '@/lib/supabase/client'
import { useSearchParams } from 'next/navigation'

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
  const [customerName, setCustomerName] = useState('')
  const [customerNotes, setCustomerNotes] = useState('')
  const [showRejectionForm, setShowRejectionForm] = useState(false)
  const [selectedAddons, setSelectedAddons] = useState<Set<string>>(new Set())
  const [calculatedTotal, setCalculatedTotal] = useState(proposal.total)
  const [isPaymentLoading, setIsPaymentLoading] = useState(false)
  const [currentPaymentStage, setCurrentPaymentStage] = useState<'deposit' | 'progress' | 'final' | null>(null)
  const searchParams = useSearchParams()
  const supabase = createClient()

  // Calculate payment amounts
  const depositAmount = proposal.total * 0.5
  const progressAmount = proposal.total * 0.3
  const finalAmount = proposal.total * 0.2

  // Check payment alerts
  useEffect(() => {
    const paymentStatus = searchParams.get('payment')
    if (paymentStatus === 'cancelled') {
      alert('Payment was cancelled. You can try again when ready.')
    } else if (paymentStatus === 'error') {
      alert('There was an error processing your payment. Please try again.')
    } else if (paymentStatus === 'success') {
      const stage = searchParams.get('stage')
      alert(`Payment successful! Your ${stage} payment has been processed.`)
    }
  }, [searchParams])

  // Track first view
  useEffect(() => {
    const trackFirstView = async () => {
      if (!proposal.first_viewed_at) {
        await supabase
          .from('proposals')
          .update({ first_viewed_at: new Date().toISOString() })
          .eq('id', proposal.id)
      }
    }

    trackFirstView()
  }, [proposal.id, proposal.first_viewed_at, supabase])

  // Calculate total with selected addons
  useEffect(() => {
    const baseItems = proposal.proposal_items.filter(item => !item.is_addon)
    const selectedAddonItems = proposal.proposal_items.filter(
      item => item.is_addon && selectedAddons.has(item.id)
    )
    
    const subtotal = [...baseItems, ...selectedAddonItems].reduce(
      (sum, item) => sum + item.total_price,
      0
    )
    
    const taxAmount = subtotal * proposal.tax_rate
    const total = subtotal + taxAmount
    
    setCalculatedTotal(total)
  }, [selectedAddons, proposal.proposal_items, proposal.tax_rate])

  const handleAddonToggle = (itemId: string) => {
    setSelectedAddons(prev => {
      const newSet = new Set(prev)
      if (newSet.has(itemId)) {
        newSet.delete(itemId)
      } else {
        newSet.add(itemId)
      }
      return newSet
    })
  }

  const handleApproval = async () => {
    if (!customerName.trim()) {
      alert('Please sign your name to approve the proposal')
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
          customerName,
          selectedAddons: Array.from(selectedAddons),
          finalTotal: calculatedTotal,
          customerNotes: customerNotes.trim() || null,
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to approve proposal')
      }

      const { proposal: updatedProposal } = await response.json()
      setProposal(updatedProposal)
      
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

  const handlePayment = async (stage: 'deposit' | 'progress' | 'final') => {
    setIsPaymentLoading(true)
    setCurrentPaymentStage(stage)
    
    try {
      let amount: number
      let description: string
      
      switch (stage) {
        case 'deposit':
          amount = depositAmount
          description = '50% Deposit Payment'
          break
        case 'progress':
          amount = progressAmount
          description = '30% Progress Payment'
          break
        case 'final':
          amount = finalAmount
          description = '20% Final Payment'
          break
      }

      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposal_id: proposal.id,
          proposal_number: proposal.proposal_number,
          customer_name: proposal.customers.name,
          customer_email: proposal.customers.email,
          amount,
          payment_type: 'card',
          description,
          payment_stage: stage
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to create payment session')
      }

      const { checkout_url } = await response.json()
      
      if (checkout_url) {
        window.location.href = checkout_url
      }
    } catch (error) {
      console.error('Error creating payment:', error)
      alert('Failed to start payment process. Please try again.')
    } finally {
      setIsPaymentLoading(false)
      setCurrentPaymentStage(null)
    }
  }

  const getPaymentStageStatus = (stage: 'deposit' | 'progress' | 'final') => {
    if (stage === 'deposit' && proposal.deposit_paid_at) return 'paid'
    if (stage === 'progress' && proposal.progress_paid_at) return 'paid'
    if (stage === 'final' && proposal.final_paid_at) return 'paid'
    
    // Check if previous stages are paid
    if (stage === 'progress' && !proposal.deposit_paid_at) return 'locked'
    if (stage === 'final' && (!proposal.deposit_paid_at || !proposal.progress_paid_at)) return 'locked'
    
    return 'available'
  }

  const totalPaidAmount = (proposal.deposit_amount || 0) + 
                         (proposal.progress_payment_amount || 0) + 
                         (proposal.final_payment_amount || 0)
  
  const paymentProgress = proposal.total > 0 ? (totalPaidAmount / proposal.total) * 100 : 0

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

  const isApproved = proposal.status === 'approved' && proposal.approved_at

  // Show payment stages for approved proposals
  const showPaymentStages = isApproved && (
    !proposal.final_paid_at || // Not fully paid
    (proposal.deposit_paid_at || proposal.progress_paid_at || proposal.final_paid_at) // Or has any payments
  )
  const isRejected = proposal.status === 'rejected' && proposal.rejected_at

  // Show payment stages for approved proposals
  const showPaymentStages = isApproved && (
    !proposal.final_paid_at || // Not fully paid
    (proposal.deposit_paid_at || proposal.progress_paid_at || proposal.final_paid_at) // Or has any payments
  )
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
          
        </div>

        {/* Payment Stages */}
        {showPaymentStages && (
          <PaymentStages proposal={proposal} />
        )}

        <div className="bg-white shadow-sm rounded-lg p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Customer</p>
              <p className="font-medium">{proposal.customers.name}</p>
              <p className="text-sm text-gray-600">{proposal.customers.email}</p>
              <p className="text-sm text-gray-600">{proposal.customers.phone}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Proposal Date</p>
              <p className="font-medium">{formatDate(proposal.created_at)}</p>
              {proposal.valid_until && (
                <>
                  <p className="text-sm text-gray-600 mt-2">Valid Until</p>
                  <p className="font-medium">{formatDate(proposal.valid_until)}</p>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Proposal Details */}
        <div className="bg-white shadow-sm rounded-lg p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">{proposal.title}</h2>
          {proposal.description && (
            <p className="text-gray-600 mb-6 whitespace-pre-wrap">{proposal.description}</p>
          )}

          <div className="space-y-4">
            <h3 className="font-medium text-gray-900">Services & Items</h3>
            
            {/* Base Items */}
            {proposal.proposal_items
              .filter(item => !item.is_addon)
              .map(item => (
                <div key={item.id} className="flex justify-between py-2 border-b">
                  <div className="flex-1">
                    <p className="font-medium">{item.name || item.description}</p>
                    {item.description && item.name && (
                      <p className="text-sm text-gray-600">{item.description}</p>
                    )}
                    <p className="text-sm text-gray-600">
                      {item.quantity} × {formatCurrency(item.unit_price)}
                    </p>
                  </div>
                  <p className="font-medium">{formatCurrency(item.total_price)}</p>
                </div>
              ))}

            {/* Add-on Items */}
            {proposal.proposal_items.some(item => item.is_addon) && (
              <>
                <h3 className="font-medium text-gray-900 mt-6">Optional Add-ons</h3>
                {proposal.proposal_items
                  .filter(item => item.is_addon)
                  .map(item => (
                    <div key={item.id} className="flex justify-between py-2 border-b">
                      <div className="flex items-center flex-1">
                        <input
                          type="checkbox"
                          id={`addon-${item.id}`}
                          checked={selectedAddons.has(item.id)}
                          onChange={() => handleAddonToggle(item.id)}
                          disabled={!isPending}
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <label htmlFor={`addon-${item.id}`} className="ml-3">
                          <p className="font-medium">{item.name || item.description}</p>
                          {item.description && item.name && (
                            <p className="text-sm text-gray-600">{item.description}</p>
                          )}
                          <p className="text-sm text-gray-600">
                            {item.quantity} × {formatCurrency(item.unit_price)}
                          </p>
                        </label>
                      </div>
                      <p className="font-medium">{formatCurrency(item.total_price)}</p>
                    </div>
                  ))}
              </>
            )}

            {/* Totals */}
            <div className="pt-4 space-y-2">
              <div className="flex justify-between text-gray-600">
                <span>Subtotal</span>
                <span>{formatCurrency(calculatedTotal / (1 + proposal.tax_rate))}</span>
              </div>
              <div className="flex justify-between text-gray-600">
                <span>Tax ({(proposal.tax_rate * 100).toFixed(2)}%)</span>
                <span>{formatCurrency(calculatedTotal - calculatedTotal / (1 + proposal.tax_rate))}</span>
              </div>
              <div className="flex justify-between text-xl font-bold">
                <span>Total</span>
                <span>{formatCurrency(calculatedTotal)}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Payment Progress - Show only if approved */}
        {isApproved && (
          <div className="bg-white shadow-sm rounded-lg p-6 mb-6">
            <h2 className="text-xl font-semibold mb-4">Payment Progress</h2>
            
            {/* Progress Bar */}
            <div className="mb-6">
              <div className="flex justify-between text-sm text-gray-600 mb-2">
                <span>Payment Progress</span>
                <span>{paymentProgress.toFixed(0)}% Complete</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-3">
                <div 
                  className="bg-green-600 h-3 rounded-full transition-all duration-300"
                  style={{ width: `${paymentProgress}%` }}
                />
              </div>
              <div className="flex justify-between text-sm text-gray-600 mt-2">
                <span>Paid: {formatCurrency(totalPaidAmount)}</span>
                <span>Remaining: {formatCurrency(proposal.total - totalPaidAmount)}</span>
              </div>
            </div>

            {/* Payment Stages */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Deposit */}
              <div className={`border rounded-lg p-4 ${
                getPaymentStageStatus('deposit') === 'paid' ? 'border-green-500 bg-green-50' :
                getPaymentStageStatus('deposit') === 'locked' ? 'border-gray-300 bg-gray-50' :
                'border-blue-500 bg-blue-50'
              }`}>
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-semibold">50% Deposit</h3>
                  {getPaymentStageStatus('deposit') === 'paid' && (
                    <CheckCircleIcon className="w-5 h-5 text-green-600" />
                  )}
                  {getPaymentStageStatus('deposit') === 'locked' && (
                    <LockClosedIcon className="w-5 h-5 text-gray-400" />
                  )}
                </div>
                <p className="text-2xl font-bold mb-3">{formatCurrency(depositAmount)}</p>
                {getPaymentStageStatus('deposit') === 'paid' ? (
                  <p className="text-sm text-green-600">Paid on {formatDate(proposal.deposit_paid_at!)}</p>
                ) : getPaymentStageStatus('deposit') === 'available' ? (
                  <button
                    onClick={() => handlePayment('deposit')}
                    disabled={isPaymentLoading}
                    className="w-full bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isPaymentLoading && currentPaymentStage === 'deposit' ? 'Processing...' : 'Pay Deposit'}
                  </button>
                ) : (
                  <p className="text-sm text-gray-500">Complete previous payment first</p>
                )}
              </div>

              {/* Progress */}
              <div className={`border rounded-lg p-4 ${
                getPaymentStageStatus('progress') === 'paid' ? 'border-green-500 bg-green-50' :
                getPaymentStageStatus('progress') === 'locked' ? 'border-gray-300 bg-gray-50' :
                'border-blue-500 bg-blue-50'
              }`}>
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-semibold">30% Progress</h3>
                  {getPaymentStageStatus('progress') === 'paid' && (
                    <CheckCircleIcon className="w-5 h-5 text-green-600" />
                  )}
                  {getPaymentStageStatus('progress') === 'locked' && (
                    <LockClosedIcon className="w-5 h-5 text-gray-400" />
                  )}
                </div>
                <p className="text-2xl font-bold mb-3">{formatCurrency(progressAmount)}</p>
                {getPaymentStageStatus('progress') === 'paid' ? (
                  <p className="text-sm text-green-600">Paid on {formatDate(proposal.progress_paid_at!)}</p>
                ) : getPaymentStageStatus('progress') === 'available' ? (
                  <button
                    onClick={() => handlePayment('progress')}
                    disabled={isPaymentLoading}
                    className="w-full bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isPaymentLoading && currentPaymentStage === 'progress' ? 'Processing...' : 'Pay Progress'}
                  </button>
                ) : (
                  <p className="text-sm text-gray-500">Complete deposit payment first</p>
                )}
              </div>

              {/* Final */}
              <div className={`border rounded-lg p-4 ${
                getPaymentStageStatus('final') === 'paid' ? 'border-green-500 bg-green-50' :
                getPaymentStageStatus('final') === 'locked' ? 'border-gray-300 bg-gray-50' :
                'border-blue-500 bg-blue-50'
              }`}>
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-semibold">20% Final</h3>
                  {getPaymentStageStatus('final') === 'paid' && (
                    <CheckCircleIcon className="w-5 h-5 text-green-600" />
                  )}
                  {getPaymentStageStatus('final') === 'locked' && (
                    <LockClosedIcon className="w-5 h-5 text-gray-400" />
                  )}
                </div>
                <p className="text-2xl font-bold mb-3">{formatCurrency(finalAmount)}</p>
                {getPaymentStageStatus('final') === 'paid' ? (
                  <p className="text-sm text-green-600">Paid on {formatDate(proposal.final_paid_at!)}</p>
                ) : getPaymentStageStatus('final') === 'available' ? (
                  <button
                    onClick={() => handlePayment('final')}
                    disabled={isPaymentLoading}
                    className="w-full bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isPaymentLoading && currentPaymentStage === 'final' ? 'Processing...' : 'Pay Final'}
                  </button>
                ) : (
                  <p className="text-sm text-gray-500">Complete progress payment first</p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Approval/Rejection Section - Show only if pending */}
        {isPending && (
          <div className="bg-white shadow-sm rounded-lg p-6">
            <h2 className="text-xl font-semibold mb-4">Approval</h2>
            
            <div className="space-y-4">
              <div>
                <label htmlFor="customer-name" className="block text-sm font-medium text-gray-700">
                  Your Name (Digital Signature)
                </label>
                <input
                  type="text"
                  id="customer-name"
                  value={customerName}
                  onChange={(e) => setCustomerName(e.target.value)}
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                  placeholder="Type your full name to sign"
                />
              </div>

              <div>
                <label htmlFor="customer-notes" className="block text-sm font-medium text-gray-700">
                  Notes or Comments (Optional)
                </label>
                <textarea
                  id="customer-notes"
                  value={customerNotes}
                  onChange={(e) => setCustomerNotes(e.target.value)}
                  rows={3}
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                  placeholder="Any additional comments or special requests..."
                />
              </div>

              <div className="flex gap-4">
                <button
                  onClick={handleApproval}
                  disabled={isApproving || !customerName.trim()}
                  className="flex-1 bg-green-600 text-white px-6 py-3 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isApproving ? 'Approving...' : 'Approve Proposal'}
                </button>
                
                <button
                  onClick={() => setShowRejectionForm(!showRejectionForm)}
                  className="px-6 py-3 border border-red-600 text-red-600 rounded-md hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                >
                  Reject
                </button>
              </div>

              {showRejectionForm && (
                <div className="mt-4 p-4 bg-red-50 rounded-md">
                  <p className="text-sm text-red-800 mb-2">
                    Please let us know why you're rejecting this proposal:
                  </p>
                  <textarea
                    value={customerNotes}
                    onChange={(e) => setCustomerNotes(e.target.value)}
                    rows={3}
                    className="block w-full border-gray-300 rounded-md shadow-sm focus:ring-red-500 focus:border-red-500 sm:text-sm"
                    placeholder="Reason for rejection..."
                  />
                  <button
                    onClick={handleRejection}
                    disabled={isRejecting || !customerNotes.trim()}
                    className="mt-2 bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isRejecting ? 'Submitting...' : 'Submit Rejection'}
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Status Messages */}
        {isApproved && proposal.signature_data && (
          <div className="mt-6 bg-green-50 border border-green-200 rounded-md p-4">
            <div className="flex">
              <CheckCircleIcon className="h-5 w-5 text-green-400" />
              <div className="ml-3">
                <h3 className="text-sm font-medium text-green-800">Proposal Approved</h3>
                <p className="mt-1 text-sm text-green-700">
                  Signed by {proposal.signature_data} on {formatDate(proposal.signed_at!)}
                </p>
                {proposal.customer_notes && (
                  <p className="mt-2 text-sm text-green-700">
                    <span className="font-medium">Notes:</span> {proposal.customer_notes}
                  </p>
                )}
              </div>
            </div>
          </div>
        )}

        {isRejected && (
          <div className="mt-6 bg-red-50 border border-red-200 rounded-md p-4">
            <div className="flex">
              <XCircleIcon className="h-5 w-5 text-red-400" />
              <div className="ml-3">
                <h3 className="text-sm font-medium text-red-800">Proposal Rejected</h3>
                <p className="mt-1 text-sm text-red-700">
                  Rejected on {formatDate(proposal.rejected_at!)}
                </p>
                {proposal.customer_notes && (
                  <p className="mt-2 text-sm text-red-700">
                    <span className="font-medium">Reason:</span> {proposal.customer_notes}
                  </p>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
