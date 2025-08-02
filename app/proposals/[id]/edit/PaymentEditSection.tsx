'use client'

import { useState } from 'react'
import { formatCurrency } from '@/lib/utils'

interface PaymentEditSectionProps {
  proposal: any
  onUpdate: (updates: any) => void
}

export default function PaymentEditSection({ proposal, onUpdate }: PaymentEditSectionProps) {
  const [paymentData, setPaymentData] = useState({
    deposit_paid: !!proposal.deposit_paid_at,
    deposit_amount: proposal.deposit_amount || proposal.total * 0.5,
    roughin_paid: !!proposal.progress_paid_at,
    roughin_amount: proposal.progress_payment_amount || proposal.total * 0.3,
    final_paid: !!proposal.final_paid_at,
    final_amount: proposal.final_payment_amount || proposal.total * 0.2,
    payment_method: proposal.payment_method || 'card'
  })

  const handlePaymentToggle = (stage: 'deposit' | 'roughin' | 'final') => {
    const updates: any = {}
    const now = new Date().toISOString()

    switch (stage) {
      case 'deposit':
        if (!paymentData.deposit_paid) {
          updates.deposit_paid_at = now
          updates.deposit_amount = paymentData.deposit_amount
          updates.payment_status = 'deposit_paid'
        } else {
          updates.deposit_paid_at = null
          updates.deposit_amount = null
          updates.payment_status = 'pending'
        }
        setPaymentData({ ...paymentData, deposit_paid: !paymentData.deposit_paid })
        break

      case 'roughin':
        if (!paymentData.roughin_paid) {
          updates.progress_paid_at = now
          updates.progress_payment_amount = paymentData.roughin_amount
          updates.payment_status = 'roughin_paid'
        } else {
          updates.progress_paid_at = null
          updates.progress_payment_amount = null
          updates.payment_status = paymentData.deposit_paid ? 'deposit_paid' : 'pending'
        }
        setPaymentData({ ...paymentData, roughin_paid: !paymentData.roughin_paid })
        break

      case 'final':
        if (!paymentData.final_paid) {
          updates.final_paid_at = now
          updates.final_payment_amount = paymentData.final_amount
          updates.payment_status = 'paid'
        } else {
          updates.final_paid_at = null
          updates.final_payment_amount = null
          updates.payment_status = paymentData.roughin_paid ? 'roughin_paid' : 
                                 paymentData.deposit_paid ? 'deposit_paid' : 'pending'
        }
        setPaymentData({ ...paymentData, final_paid: !paymentData.final_paid })
        break
    }

    // Calculate total paid
    let totalPaid = 0
    if (stage === 'deposit' ? !paymentData.deposit_paid : paymentData.deposit_paid) {
      totalPaid += paymentData.deposit_amount
    }
    if (stage === 'roughin' ? !paymentData.roughin_paid : paymentData.roughin_paid) {
      totalPaid += paymentData.roughin_amount
    }
    if (stage === 'final' ? !paymentData.final_paid : paymentData.final_paid) {
      totalPaid += paymentData.final_amount
    }
    updates.total_paid = totalPaid

    onUpdate(updates)
  }

  const handleAmountChange = (stage: 'deposit' | 'roughin' | 'final', value: string) => {
    const amount = parseFloat(value) || 0
    const updates: any = {}

    switch (stage) {
      case 'deposit':
        setPaymentData({ ...paymentData, deposit_amount: amount })
        if (paymentData.deposit_paid) {
          updates.deposit_amount = amount
        }
        break
      case 'roughin':
        setPaymentData({ ...paymentData, roughin_amount: amount })
        if (paymentData.roughin_paid) {
          updates.progress_payment_amount = amount
        }
        break
      case 'final':
        setPaymentData({ ...paymentData, final_amount: amount })
        if (paymentData.final_paid) {
          updates.final_payment_amount = amount
        }
        break
    }

    if (Object.keys(updates).length > 0) {
      // Recalculate total paid
      let totalPaid = 0
      if (paymentData.deposit_paid) {
        totalPaid += stage === 'deposit' ? amount : paymentData.deposit_amount
      }
      if (paymentData.roughin_paid) {
        totalPaid += stage === 'roughin' ? amount : paymentData.roughin_amount
      }
      if (paymentData.final_paid) {
        totalPaid += stage === 'final' ? amount : paymentData.final_amount
      }
      updates.total_paid = totalPaid
      onUpdate(updates)
    }
  }

  if (proposal.status !== 'approved') {
    return (
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <p className="text-yellow-800">Payment tracking is only available for approved proposals.</p>
      </div>
    )
  }

  const totalPaid = (paymentData.deposit_paid ? paymentData.deposit_amount : 0) +
                   (paymentData.roughin_paid ? paymentData.roughin_amount : 0) +
                   (paymentData.final_paid ? paymentData.final_amount : 0)
  const percentage = proposal.total > 0 ? (totalPaid / proposal.total) * 100 : 0

  return (
    <div className="space-y-6">
      <div className="bg-white shadow sm:rounded-lg p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Payment Management</h3>
        
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <p className="text-sm text-blue-800">
            Use this section to manually track payments received outside of Stripe (cash, check, etc.) 
            or to correct payment records if needed.
          </p>
        </div>

        {/* Progress Overview */}
        <div className="mb-6">
          <div className="flex justify-between text-sm text-gray-600 mb-2">
            <span>Overall Payment Progress</span>
            <span>{percentage.toFixed(0)}% Complete</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div 
              className="bg-green-600 h-3 rounded-full transition-all duration-300"
              style={{ width: `${percentage}%` }}
            />
          </div>
          <div className="flex justify-between text-sm text-gray-600 mt-2">
            <span>Total Paid: {formatCurrency(totalPaid)}</span>
            <span>Total Due: {formatCurrency(proposal.total)}</span>
          </div>
        </div>

        {/* Payment Method */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Payment Method
          </label>
          <select
            value={paymentData.payment_method}
            onChange={(e) => {
              setPaymentData({ ...paymentData, payment_method: e.target.value })
              onUpdate({ payment_method: e.target.value })
            }}
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
          >
            <option value="card">Credit Card</option>
            <option value="ach">ACH/Bank Transfer</option>
            <option value="cash">Cash</option>
            <option value="check">Check</option>
            <option value="other">Other</option>
          </select>
        </div>

        {/* Payment Stages */}
        <div className="space-y-4">
          {/* Deposit */}
          <div className="border rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="deposit-paid"
                  checked={paymentData.deposit_paid}
                  onChange={() => handlePaymentToggle('deposit')}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="deposit-paid" className="ml-2 text-sm font-medium text-gray-900">
                  50% Deposit Paid
                </label>
              </div>
              <input
                type="number"
                value={paymentData.deposit_amount}
                onChange={(e) => handleAmountChange('deposit', e.target.value)}
                className="ml-4 w-32 px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                step="0.01"
              />
            </div>
            {proposal.deposit_paid_at && (
              <p className="text-xs text-gray-500 ml-6">
                Originally paid on: {new Date(proposal.deposit_paid_at).toLocaleDateString()}
              </p>
            )}
          </div>

          {/* Rough-In */}
          <div className="border rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="roughin-paid"
                  checked={paymentData.roughin_paid}
                  onChange={() => handlePaymentToggle('roughin')}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="roughin-paid" className="ml-2 text-sm font-medium text-gray-900">
                  30% Rough-In Paid
                </label>
              </div>
              <input
                type="number"
                value={paymentData.roughin_amount}
                onChange={(e) => handleAmountChange('roughin', e.target.value)}
                className="ml-4 w-32 px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                step="0.01"
              />
            </div>
            {proposal.progress_paid_at && (
              <p className="text-xs text-gray-500 ml-6">
                Originally paid on: {new Date(proposal.progress_paid_at).toLocaleDateString()}
              </p>
            )}
          </div>

          {/* Final */}
          <div className="border rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="final-paid"
                  checked={paymentData.final_paid}
                  onChange={() => handlePaymentToggle('final')}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="final-paid" className="ml-2 text-sm font-medium text-gray-900">
                  20% Final Paid
                </label>
              </div>
              <input
                type="number"
                value={paymentData.final_amount}
                onChange={(e) => handleAmountChange('final', e.target.value)}
                className="ml-4 w-32 px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                step="0.01"
              />
            </div>
            {proposal.final_paid_at && (
              <p className="text-xs text-gray-500 ml-6">
                Originally paid on: {new Date(proposal.final_paid_at).toLocaleDateString()}
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
