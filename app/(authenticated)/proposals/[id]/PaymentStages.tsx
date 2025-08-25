'use client'

import { Check } from 'lucide-react'

interface PaymentStagesProps {
  depositPaidAt: string | null
  progressPaidAt: string | null
  finalPaidAt: string | null
  depositAmount: number
  progressPaymentAmount: number
  finalPaymentAmount: number
  currentStage: 'deposit' | 'roughin' | 'final' | 'complete'
}

export function PaymentStages({
  depositPaidAt,
  progressPaidAt,
  finalPaidAt,
  depositAmount,
  progressPaymentAmount,
  finalPaymentAmount,
  currentStage
}: PaymentStagesProps) {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (date: string | null) => {
    if (!date) return null
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const stages = [
    {
      name: 'Deposit',
      amount: depositAmount,
      paidAt: depositPaidAt,
      stage: 'deposit' as const
    },
    {
      name: 'Rough-in',
      amount: progressPaymentAmount,
      paidAt: progressPaidAt,
      stage: 'roughin' as const
    },
    {
      name: 'Final',
      amount: finalPaymentAmount,
      paidAt: finalPaidAt,
      stage: 'final' as const
    }
  ]

  const getStageStatus = (stage: typeof stages[0]) => {
    if (stage.paidAt) return 'completed'
    if (stage.stage === currentStage) return 'current'
    return 'pending'
  }

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-lg font-semibold mb-4">Payment Progress</h3>
      
      <div className="space-y-4">
        {stages.map((stage, index) => {
          const status = getStageStatus(stage)
          
          return (
            <div key={stage.stage} className="flex items-center">
              <div className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${
                status === 'completed' ? 'bg-green-500' :
                status === 'current' ? 'bg-blue-500' :
                'bg-gray-300'
              }`}>
                {status === 'completed' ? (
                  <Check className="w-6 h-6 text-white" />
                ) : (
                  <span className="text-white font-semibold">{index + 1}</span>
                )}
              </div>
              
              <div className="ml-4 flex-1">
                <div className="flex justify-between items-start">
                  <div>
                    <p className={`font-medium ${
                      status === 'completed' ? 'text-green-700' :
                      status === 'current' ? 'text-blue-700' :
                      'text-gray-500'
                    }`}>
                      {stage.name}
                    </p>
                    {stage.paidAt && (
                      <p className="text-sm text-gray-500">
                        Paid on {formatDate(stage.paidAt)}
                      </p>
                    )}
                  </div>
                  <p className={`font-semibold ${
                    status === 'completed' ? 'text-green-700' :
                    status === 'current' ? 'text-blue-700' :
                    'text-gray-500'
                  }`}>
                    {formatCurrency(stage.amount)}
                  </p>
                </div>
              </div>
            </div>
          )
        })}
      </div>
      
      <div className="mt-6 pt-4 border-t">
        <div className="flex justify-between items-center">
          <p className="font-semibold text-gray-900">Total Amount</p>
          <p className="font-bold text-xl">
            {formatCurrency(depositAmount + progressPaymentAmount + finalPaymentAmount)}
          </p>
        </div>
      </div>
    </div>
  )
}
