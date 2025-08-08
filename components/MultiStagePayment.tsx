'use client'

import { useState, useEffect } from 'react'
import { CheckCircleIcon, LockClosedIcon, CreditCardIcon } from '@heroicons/react/24/solid'
import { createClient } from '@/lib/supabase/client'

interface PaymentStage {
  name: string
  label: string
  percentage: number
  amount: number
  paid: boolean
  paidAt?: string
  paidAmount?: number
}

interface MultiStagePaymentProps {
  proposalId: string
  proposalNumber: string
  customerName: string
  customerEmail: string
  totalAmount: number
  depositAmount?: number
  progressAmount?: number
  finalAmount?: number
  depositPaidAt?: string
  progressPaidAt?: string
  finalPaidAt?: string
  onPaymentInitiated?: () => void
}

export default function MultiStagePayment({
  proposalId,
  proposalNumber,
  customerName,
  customerEmail,
  totalAmount,
  depositAmount,
  progressAmount,
  finalAmount,
  depositPaidAt,
  progressPaidAt,
  finalPaidAt,
  onPaymentInitiated
}: MultiStagePaymentProps) {
  const [isProcessing, setIsProcessing] = useState(false)
  const [currentStage, setCurrentStage] = useState<string>('')
  const supabase = createClient()

  // Calculate payment amounts
  const deposit = totalAmount * 0.5
  const roughIn = totalAmount * 0.3
  const final = totalAmount * 0.2

  const stages: PaymentStage[] = [
    {
      name: 'deposit',
      label: 'Deposit',
      percentage: 50,
      amount: deposit,
      paid: !!depositPaidAt,
      paidAt: depositPaidAt,
      paidAmount: depositAmount
    },
    {
      name: 'roughin',
      label: 'Rough In',
      percentage: 30,
      amount: roughIn,
      paid: !!progressPaidAt,
      paidAt: progressPaidAt,
      paidAmount: progressAmount
    },
    {
      name: 'final',
      label: 'Final Payment',
      percentage: 20,
      amount: final,
      paid: !!finalPaidAt,
      paidAt: finalPaidAt,
      paidAmount: finalAmount
    }
  ]

  // Determine current payable stage
  useEffect(() => {
    if (!depositPaidAt) {
      setCurrentStage('deposit')
    } else if (!progressPaidAt) {
      setCurrentStage('roughin')
    } else if (!finalPaidAt) {
      setCurrentStage('final')
    } else {
      setCurrentStage('complete')
    }
  }, [depositPaidAt, progressPaidAt, finalPaidAt])

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    }).format(new Date(dateString))
  }

  const handlePayment = async (stage: PaymentStage) => {
    if (stage.name !== currentStage) {
      alert('Please complete payments in order')
      return
    }

    setIsProcessing(true)
    
    try {
      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposal_id: proposalId,
          proposal_number: proposalNumber,
          customer_name: customerName,
          customer_email: customerEmail,
          amount: stage.amount,
          payment_type: 'card',
          payment_stage: stage.name,
          description: `${stage.label} Payment (${stage.percentage}%) for Proposal ${proposalNumber}`
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to create payment session')
      }

      if (data.checkout_url) {
        onPaymentInitiated?.()
        // Redirect to Stripe checkout
        window.location.href = data.checkout_url
      }
    } catch (error: any) {
      console.error('Payment error:', error)
      alert(error.message || 'Error setting up payment. Please try again.')
      setIsProcessing(false)
    }
  }

  // Calculate total paid and progress
  const totalPaid = (depositAmount || 0) + (progressAmount || 0) + (finalAmount || 0)
  const progressPercentage = totalAmount > 0 ? (totalPaid / totalAmount) * 100 : 0

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <h3 className="text-lg font-semibold mb-4">Payment Schedule</h3>
      
      {/* Progress Bar */}
      <div className="mb-6">
        <div className="flex justify-between text-sm mb-2">
          <span className="font-medium">Payment Progress</span>
          <span className="text-gray-600">{progressPercentage.toFixed(0)}% Complete</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-3">
          <div 
            className="bg-green-500 h-3 rounded-full transition-all duration-500"
            style={{ width: `${progressPercentage}%` }}
          />
        </div>
        <div className="flex justify-between mt-2 text-sm">
          <span className="text-gray-600">
            {formatCurrency(totalPaid)} paid
          </span>
          <span className="font-medium">
            Total: {formatCurrency(totalAmount)}
          </span>
          <span className="text-gray-600">
            {formatCurrency(totalAmount - totalPaid)} remaining
          </span>
        </div>
      </div>

      {/* Payment Stages */}
      <div className="space-y-3">
        {stages.map((stage) => {
          const isCurrentStage = stage.name === currentStage
          const isLocked = !stage.paid && stage.name !== currentStage && currentStage !== 'complete'
          
          return (
            <div
              key={stage.name}
              className={`border rounded-lg p-4 transition-all ${
                stage.paid 
                  ? 'bg-green-50 border-green-300'
                  : isCurrentStage
                  ? 'bg-blue-50 border-blue-300 shadow-md'
                  : 'bg-gray-50 border-gray-200 opacity-60'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    {stage.paid ? (
                      <CheckCircleIcon className="h-5 w-5 text-green-600" />
                    ) : isLocked ? (
                      <LockClosedIcon className="h-5 w-5 text-gray-400" />
                    ) : (
                      <CreditCardIcon className="h-5 w-5 text-blue-600" />
                    )}
                    <h4 className="font-semibold text-gray-900">
                      {stage.label}
                    </h4>
                    <span className="text-sm text-gray-600">
                      ({stage.percentage}%)
                    </span>
                  </div>
                  
                  {stage.paid && stage.paidAt && (
                    <p className="text-sm text-green-600 ml-7">
                      ✓ Paid on {formatDate(stage.paidAt)}
                    </p>
                  )}
                  
                  {isCurrentStage && !stage.paid && (
                    <p className="text-sm text-blue-600 ml-7">
                      Ready for payment
                    </p>
                  )}
                  
                  {isLocked && (
                    <p className="text-sm text-gray-500 ml-7">
                      Available after previous payment
                    </p>
                  )}
                </div>
                
                <div className="text-right">
                  <p className="font-bold text-lg text-gray-900">
                    {formatCurrency(stage.amount)}
                  </p>
                  
                  {!stage.paid && isCurrentStage && (
                    <button
                      onClick={() => handlePayment(stage)}
                      disabled={isProcessing}
                      className="mt-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
                    >
                      {isProcessing ? 'Processing...' : 'Pay Now'}
                    </button>
                  )}
                  
                  {stage.paid && stage.paidAmount && (
                    <p className="text-xs text-gray-500 mt-1">
                      Amount paid: {formatCurrency(stage.paidAmount)}
                    </p>
                  )}
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {currentStage === 'complete' && (
        <div className="mt-4 p-4 bg-green-100 border border-green-300 rounded-lg">
          <p className="text-green-800 font-medium text-center">
            ✅ All payments completed! Thank you for your business.
          </p>
        </div>
      )}
    </div>
  )
}
