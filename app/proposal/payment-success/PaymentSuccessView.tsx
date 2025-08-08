'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { CheckCircle } from 'lucide-react'
import { formatCurrency } from '@/lib/utils'
import type { Proposal, Customer } from '@/app/types'

interface PaymentSuccessViewProps {
  proposal: Proposal & {
    customers: Customer
  }
  sessionId: string
}

export default function PaymentSuccessView({ 
  proposal, 
  sessionId 
}: PaymentSuccessViewProps) {
  const [paymentDetails, setPaymentDetails] = useState<{
    amount: number
    stage: 'deposit' | 'roughin' | 'final'
    method: string
  } | null>(null)

  useEffect(() => {
    // Determine payment details from proposal state
    if (proposal.deposit_paid_at && !proposal.progress_paid_at) {
      setPaymentDetails({
        amount: proposal.deposit_amount || (proposal.total * 0.5),
        stage: 'deposit',
        method: proposal.payment_method || 'card'
      })
    } else if (proposal.progress_paid_at && !proposal.final_paid_at) {
      setPaymentDetails({
        amount: proposal.progress_payment_amount || (proposal.total * 0.3),
        stage: 'roughin',
        method: proposal.payment_method || 'card'
      })
    } else if (proposal.final_paid_at) {
      setPaymentDetails({
        amount: proposal.final_payment_amount || (proposal.total * 0.2),
        stage: 'final',
        method: proposal.payment_method || 'card'
      })
    }
  }, [proposal])

  const getStageLabel = (stage: string) => {
    switch (stage) {
      case 'deposit': return 'Deposit (50%)'
      case 'roughin': return 'Rough In (30%)'
      case 'final': return 'Final (20%)'
      default: return stage
    }
  }

  const getNextStage = () => {
    if (!proposal.deposit_paid_at) return 'deposit'
    if (!proposal.progress_paid_at) return 'roughin'
    if (!proposal.final_paid_at) return 'final'
    return null
  }

  if (!paymentDetails) {
    return <div>Loading payment details...</div>
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <div className="text-center mb-8">
          <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-green-100 mb-4">
            <CheckCircle className="h-10 w-10 text-green-600" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Payment Successful!</h1>
          <p className="text-gray-600 mt-2">Thank you for your payment</p>
        </div>

        <div className="border-t border-b border-gray-200 py-6 mb-6">
          <div className="space-y-4">
            <div className="flex justify-between">
              <span className="text-gray-600">Proposal Number</span>
              <span className="font-medium">{proposal.proposal_number}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Customer</span>
              <span className="font-medium">{proposal.customers.name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Payment Stage</span>
              <span className="font-medium">{getStageLabel(paymentDetails.stage)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Amount Paid</span>
              <span className="font-medium text-green-600">
                {formatCurrency(paymentDetails.amount)}
              </span>
            </div>
          </div>
        </div>

        {getNextStage() && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
            <p className="text-sm text-blue-800">
              <strong>Next Payment:</strong> {getStageLabel(getNextStage()!)}
            </p>
            <p className="text-sm text-blue-600 mt-1">
              You will be notified when the next payment is due.
            </p>
          </div>
        )}

        <div className="space-y-3">
          {proposal.customer_view_token && (
            <Link
              href={`/proposal/view/${proposal.customer_view_token}`}
              className="block w-full bg-blue-600 text-white text-center py-3 rounded-lg hover:bg-blue-700 transition"
            >
              View Proposal
            </Link>
          )}
          <Link
            href="/"
            className="block w-full bg-gray-200 text-gray-800 text-center py-3 rounded-lg hover:bg-gray-300 transition"
          >
            Return Home
          </Link>
        </div>

        <div className="mt-8 text-center text-sm text-gray-500">
          <p>A confirmation email has been sent to {proposal.customers.email}</p>
        </div>
      </div>
    </div>
  )
}
