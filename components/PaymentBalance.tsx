'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { DollarSign, CheckCircle2, Clock, AlertCircle } from 'lucide-react'

interface PaymentBalanceProps {
  proposalId: string
  depositAmount: number
  progressAmount: number
  finalAmount: number
  total: number
}

interface PaymentRecord {
  id: string
  payment_stage: string
  amount: number
  payment_method: string
  payment_date: string
  notes?: string
}

export default function PaymentBalance({ 
  proposalId, 
  depositAmount, 
  progressAmount, 
  finalAmount,
  total 
}: PaymentBalanceProps) {
  const [payments, setPayments] = useState<PaymentRecord[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchPayments()
  }, [proposalId])

  const fetchPayments = async () => {
    const supabase = createClient()
    const { data, error } = await supabase
      .from('manual_payments')
      .select('*')
      .eq('proposal_id', proposalId)
      .order('created_at', { ascending: true })

    if (!error && data) {
      setPayments(data)
    }
    setLoading(false)
  }

  // Calculate totals by stage
  const depositPaid = payments
    .filter(p => p.payment_stage === 'deposit')
    .reduce((sum, p) => sum + Number(p.amount), 0)
  
  const progressPaid = payments
    .filter(p => p.payment_stage === 'progress')
    .reduce((sum, p) => sum + Number(p.amount), 0)
  
  const finalPaid = payments
    .filter(p => p.payment_stage === 'final')
    .reduce((sum, p) => sum + Number(p.amount), 0)

  const totalPaid = depositPaid + progressPaid + finalPaid
  const remainingBalance = total - totalPaid

  // Calculate what's due for each stage
  const depositDue = Math.max(0, depositAmount - depositPaid)
  const progressDue = Math.max(0, progressAmount - progressPaid)
  const finalDue = Math.max(0, finalAmount - finalPaid)

  // Handle overpayments (if someone pays extra on deposit, it should apply to next stage)
  const depositOverpayment = Math.max(0, depositPaid - depositAmount)
  const progressOverpayment = Math.max(0, progressPaid - progressAmount)

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  if (loading) {
    return <div>Loading payment information...</div>
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <DollarSign className="h-5 w-5" />
          Payment Summary
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Overall Summary */}
        <div className="bg-gray-50 p-4 rounded-lg">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Total Contract</p>
              <p className="text-xl font-bold">{formatCurrency(total)}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Paid</p>
              <p className="text-xl font-bold text-green-600">{formatCurrency(totalPaid)}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Remaining Balance</p>
              <p className="text-xl font-bold text-orange-600">{formatCurrency(remainingBalance)}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Completion</p>
              <p className="text-xl font-bold">{((totalPaid / total) * 100).toFixed(1)}%</p>
            </div>
          </div>
        </div>

        {/* Stage Breakdown */}
        <div className="space-y-3">
          {/* Deposit Stage */}
          <div className="border rounded-lg p-3">
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-medium">Deposit (50%)</span>
                  {depositPaid >= depositAmount ? (
                    <Badge className="bg-green-500 text-white">
                      <CheckCircle2 className="h-3 w-3 mr-1" />
                      Paid
                    </Badge>
                  ) : depositDue > 0 ? (
                    <Badge variant="outline" className="text-orange-600">
                      <Clock className="h-3 w-3 mr-1" />
                      Due
                    </Badge>
                  ) : null}
                </div>
                <div className="text-sm text-gray-600">
                  Expected: {formatCurrency(depositAmount)}
                </div>
                <div className="text-sm">
                  Paid: <span className={depositPaid >= depositAmount ? 'text-green-600' : ''}>{formatCurrency(depositPaid)}</span>
                  {depositDue > 0 && <span className="text-orange-600 ml-2">({formatCurrency(depositDue)} remaining)</span>}
                  {depositOverpayment > 0 && <span className="text-blue-600 ml-2">(+{formatCurrency(depositOverpayment)} overpaid)</span>}
                </div>
              </div>
            </div>
          </div>

          {/* Progress Stage */}
          <div className="border rounded-lg p-3">
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-medium">Progress/Rough-in (30%)</span>
                  {progressPaid >= progressAmount ? (
                    <Badge className="bg-green-500 text-white">
                      <CheckCircle2 className="h-3 w-3 mr-1" />
                      Paid
                    </Badge>
                  ) : progressDue > 0 && depositPaid >= depositAmount ? (
                    <Badge variant="outline" className="text-orange-600">
                      <Clock className="h-3 w-3 mr-1" />
                      Due
                    </Badge>
                  ) : null}
                </div>
                <div className="text-sm text-gray-600">
                  Expected: {formatCurrency(progressAmount)}
                </div>
                <div className="text-sm">
                  Paid: <span className={progressPaid >= progressAmount ? 'text-green-600' : ''}>{formatCurrency(progressPaid)}</span>
                  {progressDue > 0 && <span className="text-orange-600 ml-2">({formatCurrency(progressDue)} remaining)</span>}
                  {progressOverpayment > 0 && <span className="text-blue-600 ml-2">(+{formatCurrency(progressOverpayment)} overpaid)</span>}
                </div>
              </div>
            </div>
          </div>

          {/* Final Stage */}
          <div className="border rounded-lg p-3">
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-medium">Final (20%)</span>
                  {finalPaid >= finalAmount ? (
                    <Badge className="bg-green-500 text-white">
                      <CheckCircle2 className="h-3 w-3 mr-1" />
                      Paid
                    </Badge>
                  ) : finalDue > 0 && progressPaid >= progressAmount ? (
                    <Badge variant="outline" className="text-orange-600">
                      <Clock className="h-3 w-3 mr-1" />
                      Due
                    </Badge>
                  ) : null}
                </div>
                <div className="text-sm text-gray-600">
                  Expected: {formatCurrency(finalAmount)}
                </div>
                <div className="text-sm">
                  Paid: <span className={finalPaid >= finalAmount ? 'text-green-600' : ''}>{formatCurrency(finalPaid)}</span>
                  {finalDue > 0 && <span className="text-orange-600 ml-2">({formatCurrency(finalDue)} remaining)</span>}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Payment History */}
        {payments.length > 0 && (
          <div className="mt-4 pt-4 border-t">
            <h4 className="font-medium mb-2">Payment History</h4>
            <div className="space-y-2">
              {payments.map((payment) => (
                <div key={payment.id} className="text-sm flex justify-between items-center">
                  <div>
                    <span className="text-gray-600">
                      {new Date(payment.payment_date).toLocaleDateString()} - 
                    </span>
                    <span className="ml-1 capitalize">{payment.payment_stage} payment</span>
                    <span className="ml-1 text-gray-500">({payment.payment_method})</span>
                    {payment.notes && <span className="ml-1 text-gray-400">- {payment.notes}</span>}
                  </div>
                  <span className="font-medium">{formatCurrency(payment.amount)}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Warning for overpayments */}
        {(depositOverpayment > 0 || progressOverpayment > 0) && (
          <div className="bg-blue-50 text-blue-700 p-3 rounded-lg text-sm flex items-start gap-2">
            <AlertCircle className="h-4 w-4 mt-0.5" />
            <div>
              <p className="font-medium">Overpayment Detected</p>
              <p>Customer has overpaid on one or more stages. Consider applying the overpayment to the next stage or issuing a refund.</p>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  )
}