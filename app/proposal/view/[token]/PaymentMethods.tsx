'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface PaymentMethodsProps {
  proposalId: string
  proposalNumber: string
  customerName: string
  customerEmail: string
  totalAmount: number
  depositAmount: number
  paymentStage?: 'deposit' | 'roughin' | 'final'
  onPaymentSuccess: () => void
}

export default function PaymentMethods({
  proposalId,
  proposalNumber,
  customerName,
  customerEmail,
  totalAmount,
  depositAmount,
  paymentStage = 'deposit',
  onPaymentSuccess
}: PaymentMethodsProps) {
  const [selectedMethod, setSelectedMethod] = useState<'card' | 'ach' | 'bank' | null>(null)
  const [isProcessing, setIsProcessing] = useState(false)
  const [showBankDetails, setShowBankDetails] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const supabase = createClient()

  const handleStripePayment = async (paymentType: 'card' | 'ach') => {
    setIsProcessing(true)
    setError(null)
    
    try {
      console.log('Creating payment session...', {
        proposal_id: proposalId,
        amount: depositAmount,
        payment_type: paymentType,
        payment_stage: paymentStage
      })

      // Create Stripe checkout session
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
          amount: depositAmount,
          payment_type: paymentType,
          payment_stage: paymentStage,
          description: paymentStage === 'deposit' 
            ? `Deposit for Proposal ${proposalNumber}`
            : paymentStage === 'roughin'
            ? `Rough-in Payment for Proposal ${proposalNumber}`
            : `Final Payment for Proposal ${proposalNumber}`
        })
      })

      if (!response.ok) {
        const errorText = await response.text()
        console.error('Payment API error response:', errorText)
        throw new Error(`Payment API error: ${response.status} ${response.statusText}`)
      }

      const data = await response.json()
      console.log('Payment session created:', data)

      if (data.error) {
        throw new Error(data.error)
      }

      if (!data.checkout_url) {
        console.error('No checkout URL received:', data)
        throw new Error('No checkout URL received from payment API')
      }

      // Redirect to Stripe checkout
      console.log('Redirecting to Stripe checkout:', data.checkout_url)
      window.location.href = data.checkout_url
      
    } catch (error: any) {
      console.error('Error creating payment:', error)
      setError(error.message || 'Error setting up payment. Please try again or contact us.')
      setIsProcessing(false)
    }
  }

  const handleBankTransfer = () => {
    setSelectedMethod('bank')
    setShowBankDetails(true)
  }

  const formatAmount = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  return (
    <div className="bg-white rounded-lg shadow-sm p-6">
      <h2 className="text-xl font-semibold mb-4">Payment Options</h2>
      
      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error}
        </div>
      )}

      {!showBankDetails ? (
        <>
          <p className="text-gray-600 mb-6">
            Amount Due: <span className="font-bold text-2xl text-gray-900">{formatAmount(depositAmount)}</span>
          </p>

          <div className="space-y-3">
            <button
              onClick={() => handleStripePayment('card')}
              disabled={isProcessing}
              className="w-full bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
            >
              {isProcessing ? (
                <>
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Processing...
                </>
              ) : (
                <>
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                  </svg>
                  Pay with Credit/Debit Card
                </>
              )}
            </button>

            <button
              onClick={() => handleStripePayment('ach')}
              disabled={isProcessing}
              className="w-full bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
            >
              {isProcessing ? (
                <>
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Processing...
                </>
              ) : (
                <>
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                  </svg>
                  Pay with Bank Account (ACH)
                </>
              )}
            </button>

            <button
              onClick={handleBankTransfer}
              disabled={isProcessing}
              className="w-full bg-gray-600 text-white px-6 py-3 rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
            >
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z" />
              </svg>
              Pay by Bank Transfer
            </button>
          </div>

          <p className="text-xs text-gray-500 mt-4 text-center">
            Payments are processed securely through Stripe
          </p>
        </>
      ) : (
        <div className="space-y-4">
          <h3 className="font-medium text-lg">Bank Transfer Instructions</h3>
          <div className="bg-gray-50 p-4 rounded-lg">
            <p className="text-sm text-gray-700 mb-2">Please transfer the payment to:</p>
            <div className="space-y-2 text-sm">
              <div>
                <span className="font-medium">Bank Name:</span> Your Bank Name
              </div>
              <div>
                <span className="font-medium">Account Name:</span> Your Business Name
              </div>
              <div>
                <span className="font-medium">Account Number:</span> XXXX-XXXX-XXXX
              </div>
              <div>
                <span className="font-medium">Routing Number:</span> XXXXXXXXX
              </div>
              <div>
                <span className="font-medium">Reference:</span> Proposal #{proposalNumber}
              </div>
              <div>
                <span className="font-medium">Amount:</span> {formatAmount(depositAmount)}
              </div>
            </div>
          </div>
          <p className="text-sm text-gray-600">
            Please email us at support@servicepro.com once the transfer is complete.
          </p>
          <button
            onClick={() => setShowBankDetails(false)}
            className="text-blue-600 hover:text-blue-700 text-sm"
          >
            ← Back to payment options
          </button>
        </div>
      )}
    </div>
  )
}
