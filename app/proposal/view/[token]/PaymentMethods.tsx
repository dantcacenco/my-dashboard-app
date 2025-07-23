'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface PaymentMethodsProps {
  proposalId: string
  proposalNumber: string
  customerName: string
  customerEmail: string
  totalAmount: number
  depositAmount: number // 50% deposit
  onPaymentSuccess: () => void
}

export default function PaymentMethods({
  proposalId,
  proposalNumber,
  customerName,
  customerEmail,
  totalAmount,
  depositAmount,
  onPaymentSuccess
}: PaymentMethodsProps) {
  const [selectedMethod, setSelectedMethod] = useState<'card' | 'ach' | 'bank' | null>(null)
  const [isProcessing, setIsProcessing] = useState(false)
  const [showBankDetails, setShowBankDetails] = useState(false)

  const supabase = createClient()

  const handleStripePayment = async (paymentType: 'card' | 'ach') => {
    setIsProcessing(true)
    
    try {
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
          description: `Deposit for Proposal ${proposalNumber}`
        })
      })

      const { checkout_url, error } = await response.json()

      if (error) {
        throw new Error(error)
      }

      // Redirect to Stripe checkout
      window.location.href = checkout_url
      
    } catch (error) {
      console.error('Error creating payment:', error)
      alert('Error setting up payment. Please try again or contact us.')
    } finally {
      setIsProcessing(false)
    }
  }

  const handleBankTransfer = async () => {
    try {
      // Log the bank transfer request
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'bank_transfer_requested',
          description: `Customer ${customerName} requested bank transfer instructions`,
          metadata: {
            customer_email: customerEmail,
            amount: depositAmount,
            requested_at: new Date().toISOString()
          }
        })

      // Update proposal status to indicate payment is pending
      await supabase
        .from('proposals')
        .update({ 
          payment_status: 'bank_transfer_pending',
          payment_method: 'bank_transfer'
        })
        .eq('id', proposalId)

      // Send notification to business about bank transfer request
      await fetch('/api/bank-transfer-notification', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposal_id: proposalId,
          proposal_number: proposalNumber,
          customer_name: customerName,
          customer_email: customerEmail,
          amount: depositAmount
        })
      })

      setShowBankDetails(true)
      
    } catch (error) {
      console.error('Error requesting bank transfer:', error)
      alert('Error processing request. Please contact us directly.')
    }
  }

  if (showBankDetails) {
    return (
      <div className="bg-white rounded-lg shadow-sm p-6">
        <div className="text-center mb-6">
          <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-900">Bank Transfer Instructions</h3>
          <p className="text-gray-600">Please use the following details to send your deposit payment</p>
        </div>

        <div className="bg-gray-50 rounded-lg p-4 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <span className="font-medium text-gray-700">Bank Name:</span>
              <p>Chase Bank</p>
            </div>
            <div>
              <span className="font-medium text-gray-700">Account Name:</span>
              <p>Service Pro LLC</p>
            </div>
            <div>
              <span className="font-medium text-gray-700">Routing Number:</span>
              <p>021000021</p>
            </div>
            <div>
              <span className="font-medium text-gray-700">Account Number:</span>
              <p>1234567890</p>
            </div>
            <div className="md:col-span-2">
              <span className="font-medium text-gray-700">Reference:</span>
              <p className="font-mono bg-white px-2 py-1 rounded border">
                Proposal {proposalNumber} - {customerName}
              </p>
            </div>
            <div className="md:col-span-2">
              <span className="font-medium text-gray-700">Amount:</span>
              <p className="text-lg font-bold text-green-600">
                ${depositAmount.toFixed(2)}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
          <div className="flex items-start">
            <svg className="w-5 h-5 text-yellow-600 mt-0.5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
            <div className="text-sm">
              <p className="font-medium text-yellow-800">Important:</p>
              <ul className="text-yellow-700 mt-1 space-y-1">
                <li>• Please include the reference number exactly as shown</li>
                <li>• Allow 2-3 business days for transfer processing</li>
                <li>• We'll email you once payment is received</li>
                <li>• Keep your bank receipt for records</li>
              </ul>
            </div>
          </div>
        </div>

        <div className="text-center">
          <p className="text-sm text-gray-600">
            Questions about payment? Contact us at (555) 123-4567 or info@servicepro.com
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="bg-white rounded-lg shadow-sm p-6">
      <div className="text-center mb-6">
        <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h3 className="text-lg font-semibold text-gray-900">Proposal Approved!</h3>
        <p className="text-gray-600">Ready to get started? Pay your deposit to begin work.</p>
      </div>

      <div className="bg-blue-50 rounded-lg p-4 mb-6">
        <div className="flex justify-between items-center">
          <div>
            <span className="text-sm text-blue-800">Deposit Required (50%):</span>
            <p className="text-2xl font-bold text-blue-900">${depositAmount.toFixed(2)}</p>
          </div>
          <div className="text-right">
            <span className="text-sm text-blue-800">Total Project:</span>
            <p className="text-lg font-semibold text-blue-900">${totalAmount.toFixed(2)}</p>
          </div>
        </div>
        <p className="text-xs text-blue-700 mt-2">
          Remaining ${(totalAmount - depositAmount).toFixed(2)} due upon completion
        </p>
      </div>

      <div className="space-y-4">
        <h4 className="font-medium text-gray-900">Choose Payment Method:</h4>
        
        {/* Credit/Debit Card */}
        <div 
          className={`border rounded-lg p-4 cursor-pointer transition-colors ${
            selectedMethod === 'card' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
          }`}
          onClick={() => setSelectedMethod('card')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center mr-3">
                <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                </svg>
              </div>
              <div>
                <p className="font-medium">Credit/Debit Card</p>
                <p className="text-sm text-gray-600">Visa, Mastercard, American Express</p>
              </div>
            </div>
            <div className="flex items-center">
              <span className="text-sm text-green-600 mr-2">Instant</span>
              <input 
                type="radio" 
                checked={selectedMethod === 'card'} 
                onChange={() => setSelectedMethod('card')}
                className="w-4 h-4"
              />
            </div>
          </div>
        </div>

        {/* ACH Bank Transfer */}
        <div 
          className={`border rounded-lg p-4 cursor-pointer transition-colors ${
            selectedMethod === 'ach' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
          }`}
          onClick={() => setSelectedMethod('ach')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center mr-3">
                <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z" />
                </svg>
              </div>
              <div>
                <p className="font-medium">ACH Bank Transfer</p>
                <p className="text-sm text-gray-600">Direct from your bank account</p>
              </div>
            </div>
            <div className="flex items-center">
              <span className="text-sm text-blue-600 mr-2">Lower fees</span>
              <input 
                type="radio" 
                checked={selectedMethod === 'ach'} 
                onChange={() => setSelectedMethod('ach')}
                className="w-4 h-4"
              />
            </div>
          </div>
        </div>

        {/* Manual Bank Transfer */}
        <div 
          className={`border rounded-lg p-4 cursor-pointer transition-colors ${
            selectedMethod === 'bank' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
          }`}
          onClick={() => setSelectedMethod('bank')}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center mr-3">
                <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <div>
                <p className="font-medium">Wire/Bank Transfer</p>
                <p className="text-sm text-gray-600">Traditional bank wire transfer</p>
              </div>
            </div>
            <div className="flex items-center">
              <span className="text-sm text-gray-600 mr-2">1-3 days</span>
              <input 
                type="radio" 
                checked={selectedMethod === 'bank'} 
                onChange={() => setSelectedMethod('bank')}
                className="w-4 h-4"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Action Button */}
      <div className="mt-6">
        {selectedMethod && (
          <button
            onClick={() => {
              if (selectedMethod === 'card' || selectedMethod === 'ach') {
                handleStripePayment(selectedMethod)
              } else if (selectedMethod === 'bank') {
                handleBankTransfer()
              }
            }}
            disabled={isProcessing}
            className="w-full px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 font-medium"
          >
            {isProcessing ? (
              <div className="flex items-center justify-center">
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Processing...
              </div>
            ) : (
              `Pay ${selectedMethod === 'card' ? 'with Card' : selectedMethod === 'ach' ? 'with Bank Account' : 'via Bank Transfer'}`
            )}
          </button>
        )}
      </div>

      <div className="mt-4 text-center">
        <p className="text-xs text-gray-500">
          🔒 Secure payment processing by Stripe • Your payment information is encrypted and secure
        </p>
      </div>
    </div>
  )
}