'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Check, X } from 'lucide-react'

interface ProposalData {
  id: string
  proposal_number: string
  title: string
  description: string
  subtotal: number
  tax_rate: number
  tax_amount: number
  total: number
  status: string
  customers: any
  proposal_items: any[]
  customer_view_token: string
  deposit_percentage: number
  progress_percentage: number
  final_percentage: number
  deposit_paid_at: string | null
  progress_paid_at: string | null
  final_paid_at: string | null
  deposit_amount: number | null
  progress_payment_amount: number | null
  final_payment_amount: number | null
  total_paid: number
  payment_stage: string | null
}

interface CustomerProposalViewProps {
  proposal: ProposalData
  token: string
}

export default function CustomerProposalView({ proposal: initialProposal, token }: CustomerProposalViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [proposal, setProposal] = useState(initialProposal)
  const [selectedAddons, setSelectedAddons] = useState<Set<string>>(
    new Set(initialProposal.proposal_items?.filter(item => item.is_addon && item.is_selected).map(item => item.id))
  )
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState('')

  // Refresh proposal data
  const refreshProposal = async () => {
    const { data } = await supabase
      .from('proposals')
      .select('*')
      .eq('customer_view_token', token)
      .single()
    
    if (data) {
      setProposal(data)
    }
  }

  useEffect(() => {
    // Poll for updates every 5 seconds if payment is in progress
    if (proposal.status === 'accepted' && proposal.payment_stage !== 'complete') {
      const interval = setInterval(refreshProposal, 5000)
      return () => clearInterval(interval)
    }
  }, [proposal.status, proposal.payment_stage])

  // Separate services and add-ons
  const services = proposal.proposal_items?.filter(item => !item.is_addon) || []
  const addons = proposal.proposal_items?.filter(item => item.is_addon) || []

  // Toggle addon selection
  const toggleAddon = (addonId: string) => {
    const newSelected = new Set(selectedAddons)
    if (newSelected.has(addonId)) {
      newSelected.delete(addonId)
    } else {
      newSelected.add(addonId)
    }
    setSelectedAddons(newSelected)
  }

  // Calculate totals
  const calculateTotals = () => {
    const servicesTotal = services.reduce((sum: number, item: any) => 
      sum + (item.total_price || 0), 0
    )
    
    const addonsTotal = addons
      .filter(item => selectedAddons.has(item.id))
      .reduce((sum: number, item: any) => sum + (item.total_price || 0), 0)
    
    const subtotal = servicesTotal + addonsTotal
    const taxAmount = subtotal * (proposal.tax_rate || 0)
    const total = subtotal + taxAmount
    
    return { servicesTotal, addonsTotal, subtotal, taxAmount, total }
  }

  const totals = calculateTotals()

  // Handle proposal approval - just update status, don't redirect to payment
  const handleApprove = async () => {
    setIsProcessing(true)
    setError('')

    try {
      // Update selected add-ons
      for (const addon of addons) {
        await supabase
          .from('proposal_items')
          .update({ is_selected: selectedAddons.has(addon.id) })
          .eq('id', addon.id)
      }

      // Calculate payment amounts
      const depositAmount = totals.total * 0.5
      const progressAmount = totals.total * 0.3
      const finalAmount = totals.total * 0.2

      // Update proposal status to accepted
      const { error: updateError } = await supabase
        .from('proposals')
        .update({
          subtotal: totals.subtotal,
          tax_amount: totals.taxAmount,
          total: totals.total,
          deposit_amount: depositAmount,
          progress_payment_amount: progressAmount,
          final_payment_amount: finalAmount,
          status: 'accepted',
          approved_at: new Date().toISOString(),
          payment_stage: 'deposit'
        })
        .eq('id', proposal.id)

      if (updateError) throw updateError

      // Refresh the proposal data to show payment stages
      await refreshProposal()
      
    } catch (err: any) {
      console.error('Approval error:', err)
      setError('Failed to approve proposal. Please try again.')
    } finally {
      setIsProcessing(false)
    }
  }

  // Handle payment for a specific stage
  const handlePayment = async (stage: 'deposit' | 'roughin' | 'final') => {
    setIsProcessing(true)
    setError('')

    try {
      let amount = 0
      let description = ''
      
      switch(stage) {
        case 'deposit':
          amount = proposal.deposit_amount || 0
          description = `50% Deposit for Proposal #${proposal.proposal_number}`
          break
        case 'roughin':
          amount = proposal.progress_payment_amount || 0
          description = `30% Rough-in Payment for Proposal #${proposal.proposal_number}`
          break
        case 'final':
          amount = proposal.final_payment_amount || 0
          description = `20% Final Payment for Proposal #${proposal.proposal_number}`
          break
      }

      // Create payment session
      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposal_id: proposal.id,
          proposal_number: proposal.proposal_number,
          customer_name: proposal.customers?.name,
          customer_email: proposal.customers?.email,
          amount,
          payment_type: 'card',
          payment_stage: stage,
          description
        })
      })

      const data = await response.json()
      
      if (data.checkout_url) {
        // Redirect to Stripe checkout
        window.location.href = data.checkout_url
      } else {
        throw new Error('No payment URL received')
      }
      
    } catch (err: any) {
      console.error('Payment error:', err)
      setError('Failed to process payment. Please try again.')
      setIsProcessing(false)
    }
  }

  // Handle rejection
  const handleReject = async () => {
    setIsProcessing(true)
    try {
      await supabase
        .from('proposals')
        .update({
          status: 'rejected',
          rejected_at: new Date().toISOString()
        })
        .eq('id', proposal.id)
      
      await refreshProposal()
    } catch (err) {
      setError('Failed to reject proposal')
    } finally {
      setIsProcessing(false)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  // Show payment stages if approved
  if (proposal.status === 'accepted' || proposal.status === 'approved') {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-4">
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h1 className="text-3xl font-bold mb-2">Proposal #{proposal.proposal_number}</h1>
            <div className="mb-8">
              <span className="bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm font-medium">
                Approved
              </span>
            </div>

            {/* Payment Stages */}
            <div className="space-y-6">
              <h2 className="text-xl font-semibold mb-4">Payment Schedule</h2>
              
              {/* Deposit */}
              <div className="border rounded-lg p-6">
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="font-semibold">50% Deposit</h3>
                    <p className="text-gray-600">{formatCurrency(proposal.deposit_amount || 0)}</p>
                  </div>
                  {proposal.deposit_paid_at ? (
                    <div className="flex items-center text-green-600">
                      <Check className="h-5 w-5 mr-2" />
                      Paid
                    </div>
                  ) : (
                    <button
                      onClick={() => handlePayment('deposit')}
                      disabled={isProcessing}
                      className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
                    >
                      Pay Now
                    </button>
                  )}
                </div>
              </div>

              {/* Rough-in */}
              <div className={`border rounded-lg p-6 ${!proposal.deposit_paid_at ? 'opacity-50' : ''}`}>
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="font-semibold">30% Rough-in</h3>
                    <p className="text-gray-600">{formatCurrency(proposal.progress_payment_amount || 0)}</p>
                  </div>
                  {proposal.progress_paid_at ? (
                    <div className="flex items-center text-green-600">
                      <Check className="h-5 w-5 mr-2" />
                      Paid
                    </div>
                  ) : proposal.deposit_paid_at ? (
                    <button
                      onClick={() => handlePayment('roughin')}
                      disabled={isProcessing}
                      className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
                    >
                      Pay Now
                    </button>
                  ) : (
                    <span className="text-gray-400">Locked</span>
                  )}
                </div>
              </div>

              {/* Final */}
              <div className={`border rounded-lg p-6 ${!proposal.progress_paid_at ? 'opacity-50' : ''}`}>
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="font-semibold">20% Final</h3>
                    <p className="text-gray-600">{formatCurrency(proposal.final_payment_amount || 0)}</p>
                  </div>
                  {proposal.final_paid_at ? (
                    <div className="flex items-center text-green-600">
                      <Check className="h-5 w-5 mr-2" />
                      Paid
                    </div>
                  ) : proposal.progress_paid_at ? (
                    <button
                      onClick={() => handlePayment('final')}
                      disabled={isProcessing}
                      className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
                    >
                      Pay Now
                    </button>
                  ) : (
                    <span className="text-gray-400">Locked</span>
                  )}
                </div>
              </div>
            </div>

            {error && (
              <div className="mt-4 p-4 bg-red-100 text-red-700 rounded">
                {error}
              </div>
            )}
          </div>
        </div>
      </div>
    )
  }

  // Show approval/rejection UI if not yet approved
  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h1 className="text-3xl font-bold mb-8">Proposal #{proposal.proposal_number}</h1>
          
          {/* Services and totals display */}
          <div className="space-y-6 mb-8">
            {/* ... existing services display ... */}
          </div>

          {/* Approve/Reject buttons */}
          <div className="flex gap-4 justify-center">
            <button
              onClick={handleApprove}
              disabled={isProcessing}
              className="bg-green-600 text-white px-8 py-3 rounded-lg hover:bg-green-700 disabled:opacity-50"
            >
              Approve Proposal
            </button>
            <button
              onClick={handleReject}
              disabled={isProcessing}
              className="bg-red-600 text-white px-8 py-3 rounded-lg hover:bg-red-700 disabled:opacity-50"
            >
              Reject Proposal
            </button>
          </div>

          {error && (
            <div className="mt-4 p-4 bg-red-100 text-red-700 rounded">
              {error}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
