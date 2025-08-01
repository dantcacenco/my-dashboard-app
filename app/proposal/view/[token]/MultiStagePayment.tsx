'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'

interface PaymentStage {
  name: string
  label: string
  percentage: number
  amount: number
  paid: boolean
  paidAt: string | null
}

interface MultiStagePaymentProps {
  proposalId: string
  proposalNumber: string
  customerName: string
  customerEmail: string
  proposal: any
  onPaymentComplete: () => void
}

export default function MultiStagePayment({
  proposalId,
  proposalNumber,
  customerName,
  customerEmail,
  proposal,
  onPaymentComplete
}: MultiStagePaymentProps) {
  const [isProcessing, setIsProcessing] = useState(false)
  const [paymentStages, setPaymentStages] = useState<PaymentStage[]>([])
  const supabase = createClient()

  useEffect(() => {
    // Calculate payment stages based on proposal data
    const stages = [
      {
        name: 'deposit',
        label: 'Deposit',
        percentage: proposal.deposit_percentage || 50,
        amount: proposal.deposit_amount || (proposal.total * 0.5),
        paid: proposal.deposit_paid_at !== null,
        paidAt: proposal.deposit_paid_at
      },
      {
        name: 'progress',
        label: 'Progress',
        percentage: proposal.progress_percentage || 30,
        amount: proposal.progress_amount || (proposal.total * 0.3),
        paid: proposal.progress_paid_at !== null,
        paidAt: proposal.progress_paid_at
      },
      {
        name: 'final',
        label: 'Final',
        percentage: proposal.final_percentage || 20,
        amount: proposal.final_amount || (proposal.total * 0.2),
        paid: proposal.final_paid_at !== null,
        paidAt: proposal.final_paid_at
      }
    ]
    setPaymentStages(stages)
  }, [proposal])

  const getCurrentStage = () => {
    return paymentStages.find(stage => !stage.paid) || null
  }

  const getProgressPercentage = () => {
    const paidStages = paymentStages.filter(stage => stage.paid)
    const totalPaid = paidStages.reduce((sum, stage) => sum + stage.percentage, 0)
    return totalPaid
  }

  const handlePayment = async (stage: PaymentStage) => {
    setIsProcessing(true)
    
    try {
      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposal_id: proposalId,
          proposal_number: proposalNumber,
          customer_name: customerName,
          customer_email: customerEmail,
          amount: stage.amount,
          payment_type: 'card',
          description: `${stage.label} Payment (${stage.percentage}%) for Proposal ${proposalNumber}`,
          payment_stage: stage.name,
          metadata: {
            payment_stage: stage.name,
            stage_percentage: stage.percentage
          }
        })
      })

      const { checkout_url, error } = await response.json()

      if (error) {
        throw new Error(error)
      }

      await supabase
        .from('proposals')
        .update({ 
          current_payment_stage: stage.name 
        })
        .eq('id', proposalId)

      window.location.href = checkout_url
      
    } catch (error) {
      console.error('Error creating payment:', error)
      alert('Error setting up payment. Please try again or contact us.')
    } finally {
      setIsProcessing(false)
    }
  }

  const formatDate = (dateString: string | null) => {
    if (!dateString) return ''
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const currentStage = getCurrentStage()
  const progressPercentage = getProgressPercentage()

  return (
    <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
      <h3 className="text-xl font-semibold mb-4">Payment Schedule</h3>
      
      {/* Progress Bar */}
      <div className="mb-6">
        <div className="flex justify-between text-sm text-gray-600 mb-2">
          <span>Payment Progress</span>
          <span>{progressPercentage}% Complete</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-3">
          <div 
            className="bg-green-600 h-3 rounded-full transition-all duration-500"
            style={{ width: `${progressPercentage}%` }}
          />
        </div>
      </div>

      {/* Payment Stages */}
      <div className="space-y-4">
        {paymentStages.map((stage, index) => {
          const isCurrentStage = currentStage?.name === stage.name
          const isLocked = !stage.paid && !isCurrentStage && currentStage !== null
          
          return (
            <div 
              key={stage.name}
              className={`border rounded-lg p-4 ${
                stage.paid ? 'bg-green-50 border-green-200' : 
                isLocked ? 'bg-gray-50 border-gray-200' : 
                'bg-blue-50 border-blue-200'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center">
                    <h4 className="font-medium text-lg">
                      Stage {index + 1}: {stage.label} ({stage.percentage}%)
                    </h4>
                    {stage.paid && (
                      <span className="ml-3 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        ✓ Paid
                      </span>
                    )}
                    {isLocked && (
                      <span className="ml-3 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
                        🔒 Locked
                      </span>
                    )}
                  </div>
                  <p className="text-gray-600 mt-1">
                    Amount: ${stage.amount.toFixed(2)}
                    {stage.paid && stage.paidAt && (
                      <span className="ml-2 text-sm">
                        • Paid on {formatDate(stage.paidAt)}
                      </span>
                    )}
                  </p>
                </div>
                
                {!stage.paid && isCurrentStage && (
                  <button
                    onClick={() => handlePayment(stage)}
                    disabled={isProcessing}
                    className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isProcessing ? 'Processing...' : `Pay $${stage.amount.toFixed(2)}`}
                  </button>
                )}
              </div>
            </div>
          )
        })}
      </div>

      {/* Total Summary */}
      <div className="mt-6 pt-4 border-t border-gray-200">
        <div className="flex justify-between text-lg font-medium">
          <span>Total Project Cost:</span>
          <span>${proposal.total.toFixed(2)}</span>
        </div>
        <div className="flex justify-between text-sm text-gray-600 mt-1">
          <span>Total Paid:</span>
          <span>${(proposal.total_paid || 0).toFixed(2)}</span>
        </div>
        <div className="flex justify-between text-sm text-gray-600">
          <span>Remaining:</span>
          <span>${(proposal.total - (proposal.total_paid || 0)).toFixed(2)}</span>
        </div>
      </div>
    </div>
  )
}
