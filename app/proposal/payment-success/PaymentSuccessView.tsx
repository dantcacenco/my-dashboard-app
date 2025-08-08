'use client'

import { CheckCircleIcon } from '@heroicons/react/24/solid'
import Link from 'next/link'

interface PaymentSuccessViewProps {
  proposal: any
  paymentAmount: number
  paymentMethod: string
  sessionId: string
  paymentStage: string
  nextStage: string | null
}

export default function PaymentSuccessView({
  proposal,
  paymentAmount,
  paymentMethod,
  sessionId,
  paymentStage,
  nextStage
}: PaymentSuccessViewProps) {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const getStageLabel = (stage: string) => {
    switch(stage) {
      case 'deposit': return 'Deposit (50%)'
      case 'roughin': return 'Rough In (30%)'
      case 'final': return 'Final Payment (20%)'
      default: return stage
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-3xl mx-auto px-4">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <div className="text-center mb-8">
            <CheckCircleIcon className="h-16 w-16 text-green-500 mx-auto mb-4" />
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              Payment Successful!
            </h1>
            <p className="text-gray-600">
              Thank you for your payment
            </p>
          </div>

          <div className="border-t border-b border-gray-200 py-6 mb-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">Proposal Number</p>
                <p className="font-semibold">{proposal.proposal_number}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Customer</p>
                <p className="font-semibold">{proposal.customers?.name}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Payment Stage</p>
                <p className="font-semibold">{getStageLabel(paymentStage)}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Amount Paid</p>
                <p className="font-semibold text-green-600">
                  {formatCurrency(paymentAmount)}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Payment Method</p>
                <p className="font-semibold capitalize">{paymentMethod}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Transaction ID</p>
                <p className="font-mono text-xs">{sessionId}</p>
              </div>
            </div>
          </div>

          {nextStage && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
              <p className="text-sm text-blue-800">
                <strong>Next Payment Stage:</strong> {getStageLabel(nextStage)}
              </p>
              <p className="text-sm text-blue-600 mt-1">
                You will be notified when the next payment is due.
              </p>
            </div>
          )}

          <div className="space-y-3">
            <Link
              href={`/proposal/view/${proposal.customer_view_token}`}
              className="block w-full bg-blue-600 text-white text-center py-3 rounded-lg hover:bg-blue-700 transition"
            >
              View Proposal
            </Link>
            <Link
              href="/"
              className="block w-full bg-gray-200 text-gray-800 text-center py-3 rounded-lg hover:bg-gray-300 transition"
            >
              Return Home
            </Link>
          </div>

          <div className="mt-8 text-center text-sm text-gray-500">
            <p>A confirmation email has been sent to {proposal.customers?.email}</p>
            <p className="mt-2">
              For questions, please contact us at support@servicepro.com
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
