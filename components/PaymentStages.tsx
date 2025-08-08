'use client'

import { useState, useEffect } from 'react'
import { CheckCircleIcon, LockClosedIcon } from '@heroicons/react/24/solid'
import { createClient } from '@/lib/supabase/client'

interface PaymentStagesProps {
  proposalId: string
  proposalNumber: string
  customerName: string
  customerEmail: string
  totalAmount: number
  depositPercentage?: number
  progressPercentage?: number
  finalPercentage?: number
  onPaymentInitiated?: () => void
}

export default function PaymentStages({
  proposalId,
  proposalNumber,
  customerName,
  customerEmail,
  totalAmount,
  depositPercentage = 50,
  progressPercentage = 30,
  finalPercentage = 20,
  onPaymentInitiated
}: PaymentStagesProps) {
  const [paymentStages, setPaymentStages] = useState<any[]>([])
  const [isProcessing, setIsProcessing] = useState(false)
  const [currentStage, setCurrentStage] = useState<string>('deposit')
  const supabase = createClient()

  useEffect(() => {
    loadPaymentStages()
  }, [proposalId])

  const loadPaymentStages = async () => {
    const { data: stages } = await supabase
      .from('payment_stages')
      .select('*')
      .eq('proposal_id', proposalId)
      .order('stage')

    if (stages && stages.length > 0) {
      setPaymentStages(stages)
      // Determine current stage
      const unpaidStage = stages.find(s => !s.paid)
      if (unpaidStage) {
        setCurrentStage(unpaidStage.stage)
      } else {
        setCurrentStage('complete')
      }
    } else {
      // Initialize stages if they don't exist
      const initialStages = [
        {
          stage: 'deposit',
          percentage: depositPercentage,
          amount: totalAmount * (depositPercentage / 100),
          paid: false,
          label: 'Deposit',
          description: 'Initial deposit to begin work'
        },
        {
          stage: 'roughin',
          percentage: progressPercentage,
          amount: totalAmount * (progressPercentage / 100),
          paid: false,
          label: 'Rough In',
          description: 'Payment after rough-in completion'
        },
        {
          stage: 'final',
          percentage: finalPercentage,
          amount: totalAmount * (finalPercentage / 100),
          paid: false,
          label: 'Final Payment',
          description: 'Final payment upon completion'
        }
      ]
      setPaymentStages(initialStages)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const handlePayment = async (stage: any) => {
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
          payment_stage: stage.stage,
          description: `${stage.label} for Proposal ${proposalNumber}`
        })
      })

      const { checkout_url, error } = await response.json()

      if (error) {
        throw new Error(error)
      }

      if (checkout_url) {
        onPaymentInitiated?.()
        window.location.href = checkout_url
      }
    } catch (error: any) {
      console.error('Payment error:', error)
      alert('Error setting up payment. Please try again.')
      setIsProcessing(false)
    }
  }

  const totalPaid = paymentStages
    .filter(s => s.paid)
    .reduce((sum, s) => sum + Number(s.amount), 0)

  const progressPercentageValue = totalAmount > 0 
    ? Math.round((totalPaid / totalAmount) * 100)
    : 0

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-lg font-semibold mb-4">Payment Schedule</h3>
      
      <div className="mb-6">
        <div className="flex justify-between text-sm mb-2">
          <span>Payment Progress</span>
          <span>{progressPercentageValue}% Complete</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-3">
          <div 
            className="bg-green-500 h-3 rounded-full transition-all duration-500"
            style={{ width: `${progressPercentageValue}%` }}
          />
        </div>
        <div className="flex justify-between mt-2 text-sm">
          <span className="text-gray-600">
            {formatCurrency(totalPaid)} paid
          </span>
          <span className="text-gray-600">
            {formatCurrency(totalAmount - totalPaid)} remaining
          </span>
        </div>
      </div>

      <div className="space-y-3">
        {paymentStages.map((stage, index) => (
          <div
            key={stage.stage}
            className={`border rounded-lg p-4 ${
              stage.paid 
                ? 'bg-green-50 border-green-300'
                : stage.stage === currentStage
                ? 'bg-blue-50 border-blue-300'
                : 'bg-gray-50 border-gray-300'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  {stage.paid ? (
                    <CheckCircleIcon className="h-5 w-5 text-green-600" />
                  ) : stage.stage !== currentStage ? (
                    <LockClosedIcon className="h-5 w-5 text-gray-400" />
                  ) : null}
                  <h4 className="font-semibold">
                    {stage.label || `Stage ${index + 1}`}
                  </h4>
                  <span className="text-sm text-gray-600">
                    ({stage.percentage}%)
                  </span>
                </div>
                <p className="text-sm text-gray-600 mt-1">
                  {stage.description}
                </p>
                {stage.paid && stage.paid_at && (
                  <p className="text-xs text-green-600 mt-1">
                    Paid on {new Date(stage.paid_at).toLocaleDateString()}
                  </p>
                )}
              </div>
              
              <div className="text-right">
                <p className="font-bold text-lg">
                  {formatCurrency(stage.amount)}
                </p>
                {!stage.paid && stage.stage === currentStage && (
                  <button
                    onClick={() => handlePayment(stage)}
                    disabled={isProcessing}
                    className="mt-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
                  >
                    {isProcessing ? 'Processing...' : 'Pay Now'}
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
