'use client'

import { useState } from 'react'
import { loadStripe } from '@stripe/stripe-js'
import { CheckCircleIcon, LockClosedIcon, ClockIcon } from '@heroicons/react/24/solid'

interface PaymentStagesProps {
  proposal: any
  onPaymentInitiated?: () => void
}

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!)

export default function PaymentStages({ proposal, onPaymentInitiated }: PaymentStagesProps) {
  const [loading, setLoading] = useState('')

  // Calculate payment amounts
  const depositAmount = proposal.total * 0.5
  const progressAmount = proposal.total * 0.3
  const finalAmount = proposal.total * 0.2

  // Determine current stage
  const getStageStatus = (stage: string) => {
    if (stage === 'deposit') {
      return proposal.deposit_paid_at ? 'completed' : 'active'
    }
    if (stage === 'progress') {
      if (proposal.progress_paid_at) return 'completed'
      if (proposal.deposit_paid_at) return 'active'
      return 'locked'
    }
    if (stage === 'final') {
      if (proposal.final_paid_at) return 'completed'
      if (proposal.progress_paid_at) return 'active'
      return 'locked'
    }
    return 'locked'
  }

  // Calculate total paid percentage
  const totalPaid = (proposal.deposit_amount || 0) + 
                    (proposal.progress_payment_amount || 0) + 
                    (proposal.final_payment_amount || 0)
  const paidPercentage = proposal.total > 0 ? (totalPaid / proposal.total) * 100 : 0

  const handlePayment = async (stage: string, amount: number) => {
    setLoading(stage)
    
    try {
      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposal_id: proposal.id,
          proposal_number: proposal.proposal_number,
          customer_name: proposal.customers.name,
          customer_email: proposal.customers.email,
          amount: Math.round(amount * 100), // Convert to cents
          payment_type: 'card',
          description: `${stage.charAt(0).toUpperCase() + stage.slice(1)} payment for Proposal #${proposal.proposal_number}`,
          payment_stage: stage
        }),
      })

      if (!response.ok) throw new Error('Failed to create payment session')

      const { sessionId } = await response.json()
      const stripe = await stripePromise

      if (!stripe) throw new Error('Stripe not loaded')

      const { error } = await stripe.redirectToCheckout({ sessionId })
      if (error) throw error

      if (onPaymentInitiated) onPaymentInitiated()
    } catch (error) {
      console.error('Payment error:', error)
      alert('Failed to initiate payment. Please try again.')
    } finally {
      setLoading('')
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const stages = [
    {
      id: 'deposit',
      name: '50% Deposit',
      amount: depositAmount,
      status: getStageStatus('deposit'),
      paidAt: proposal.deposit_paid_at,
      paidAmount: proposal.deposit_amount
    },
    {
      id: 'progress',
      name: '30% Rough In',
      amount: progressAmount,
      status: getStageStatus('progress'),
      paidAt: proposal.progress_paid_at,
      paidAmount: proposal.progress_payment_amount
    },
    {
      id: 'final',
      name: '20% Final',
      amount: finalAmount,
      status: getStageStatus('final'),
      paidAt: proposal.final_paid_at,
      paidAmount: proposal.final_payment_amount
    }
  ]

  return (
    <div className="bg-white shadow-sm rounded-lg p-6 mb-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-4">Payment Schedule</h2>
      
      {/* Progress Bar */}
      <div className="mb-6">
        <div className="flex justify-between text-sm text-gray-600 mb-2">
          <span>Total Progress</span>
          <span>{formatCurrency(totalPaid)} of {formatCurrency(proposal.total)} ({paidPercentage.toFixed(0)}%)</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-3">
          <div 
            className="bg-green-600 h-3 rounded-full transition-all duration-300"
            style={{ width: `${paidPercentage}%` }}
          />
        </div>
      </div>

      {/* Payment Stages */}
      <div className="space-y-4">
        {stages.map((stage) => (
          <div key={stage.id} className="border rounded-lg p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                {stage.status === 'completed' && <CheckCircleIcon className="w-6 h-6 text-green-600 mr-3" />}
                {stage.status === 'active' && <ClockIcon className="w-6 h-6 text-blue-600 mr-3" />}
                {stage.status === 'locked' && <LockClosedIcon className="w-6 h-6 text-gray-400 mr-3" />}
                
                <div>
                  <h3 className="font-medium text-gray-900">{stage.name}</h3>
                  {stage.status === 'completed' && stage.paidAt && (
                    <p className="text-sm text-gray-500">
                      Paid {formatCurrency(stage.paidAmount || 0)} on {new Date(stage.paidAt).toLocaleDateString()}
                    </p>
                  )}
                  {stage.status === 'active' && (
                    <p className="text-sm text-gray-500">Due now</p>
                  )}
                  {stage.status === 'locked' && (
                    <p className="text-sm text-gray-500">Available after previous payment</p>
                  )}
                </div>
              </div>

              <div className="flex items-center">
                <span className="font-semibold text-gray-900 mr-4">{formatCurrency(stage.amount)}</span>
                
                {stage.status === 'active' && (
                  <button
                    onClick={() => handlePayment(stage.id, stage.amount)}
                    disabled={loading === stage.id}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400"
                  >
                    {loading === stage.id ? 'Processing...' : 'Pay Now'}
                  </button>
                )}
                
                {stage.status === 'completed' && (
                  <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                    Paid
                  </span>
                )}
                
                {stage.status === 'locked' && (
                  <span className="px-3 py-1 bg-gray-100 text-gray-600 rounded-full text-sm font-medium">
                    Locked
                  </span>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
