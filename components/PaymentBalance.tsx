'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { DollarSign, CheckCircle2, Clock, AlertCircle, Camera, X } from 'lucide-react'

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
  check_number?: string
  check_image_url?: string
}

export default function PaymentBalance({ 
  proposalId, 
  depositAmount, 
  progressAmount, 
  finalAmount,
  total,
  onRecordPayment
}: PaymentBalanceProps & { onRecordPayment?: () => void }) {
  const [payments, setPayments] = useState<PaymentRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedCheckImage, setSelectedCheckImage] = useState<string | null>(null)

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

  // Calculate totals by stage with cascading logic
  // When a payment is made to a stage, overflow cascades to the next
  let depositApplied = 0
  let progressApplied = 0
  let finalApplied = 0
  
  // Process payments in order to apply cascading logic
  payments.forEach(payment => {
    let remainingAmount = Number(payment.amount)
    
    if (payment.payment_stage === 'deposit') {
      // Apply to deposit first
      const depositNeeded = Math.max(0, depositAmount - depositApplied)
      const applyToDeposit = Math.min(remainingAmount, depositNeeded)
      depositApplied += applyToDeposit
      remainingAmount -= applyToDeposit
      
      // Cascade to progress
      if (remainingAmount > 0) {
        const progressNeeded = Math.max(0, progressAmount - progressApplied)
        const applyToProgress = Math.min(remainingAmount, progressNeeded)
        progressApplied += applyToProgress
        remainingAmount -= applyToProgress
      }
      
      // Cascade to final
      if (remainingAmount > 0) {
        const finalNeeded = Math.max(0, finalAmount - finalApplied)
        const applyToFinal = Math.min(remainingAmount, finalNeeded)
        finalApplied += applyToFinal
      }
    } else if (payment.payment_stage === 'progress') {
      // Apply to progress first
      const progressNeeded = Math.max(0, progressAmount - progressApplied)
      const applyToProgress = Math.min(remainingAmount, progressNeeded)
      progressApplied += applyToProgress
      remainingAmount -= applyToProgress
      
      // Cascade to final
      if (remainingAmount > 0) {
        const finalNeeded = Math.max(0, finalAmount - finalApplied)
        const applyToFinal = Math.min(remainingAmount, finalNeeded)
        finalApplied += applyToFinal
      }
    } else if (payment.payment_stage === 'final') {
      finalApplied += remainingAmount
    }
  })

  const totalPaid = depositApplied + progressApplied + finalApplied
  const remainingBalance = total - totalPaid

  // Calculate what's due for each stage
  const depositDue = Math.max(0, depositAmount - depositApplied)
  const progressDue = Math.max(0, progressAmount - progressApplied)
  const finalDue = Math.max(0, finalAmount - finalApplied)

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
          <div className="space-y-3">
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
                  {depositApplied >= depositAmount ? (
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
                  Paid: <span className={depositApplied >= depositAmount ? 'text-green-600' : ''}>{formatCurrency(depositApplied)}</span>
                  {depositDue > 0 && <span className="text-orange-600 ml-2">({formatCurrency(depositDue)} remaining)</span>}
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
                  {progressApplied >= progressAmount ? (
                    <Badge className="bg-green-500 text-white">
                      <CheckCircle2 className="h-3 w-3 mr-1" />
                      Paid
                    </Badge>
                  ) : progressDue > 0 && depositApplied >= depositAmount ? (
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
                  Paid: <span className={progressApplied >= progressAmount ? 'text-green-600' : ''}>{formatCurrency(progressApplied)}</span>
                  {progressDue > 0 && <span className="text-orange-600 ml-2">({formatCurrency(progressDue)} remaining)</span>}
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
                  {finalApplied >= finalAmount ? (
                    <Badge className="bg-green-500 text-white">
                      <CheckCircle2 className="h-3 w-3 mr-1" />
                      Paid
                    </Badge>
                  ) : finalDue > 0 && progressApplied >= progressAmount ? (
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
                  Paid: <span className={finalApplied >= finalAmount ? 'text-green-600' : ''}>{formatCurrency(finalApplied)}</span>
                  {finalDue > 0 && <span className="text-orange-600 ml-2">({formatCurrency(finalDue)} remaining)</span>}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Record Payment Button */}
        {onRecordPayment && remainingBalance > 0 && (
          <div className="flex justify-center py-4">
            <Button onClick={onRecordPayment} variant="outline" size="sm">
              <DollarSign className="h-4 w-4 mr-1" />
              Record Payment
            </Button>
          </div>
        )}

        {/* Payment History */}
        {payments.length > 0 && (
          <div className="mt-4 pt-4 border-t">
            <h4 className="font-medium mb-2">Payment History</h4>
            <div className="space-y-2">
              {payments.map((payment) => (
                <div key={payment.id} className="text-sm flex justify-between items-center">
                  <div className="flex items-center gap-2">
                    <span className="text-gray-600">
                      {new Date(payment.payment_date).toLocaleDateString()} - 
                    </span>
                    <span className="ml-1 capitalize">{payment.payment_stage} payment</span>
                    <span className="ml-1 text-gray-500">({payment.payment_method})</span>
                    {payment.check_image_url && (
                      <button
                        onClick={() => setSelectedCheckImage(payment.check_image_url!)}
                        className="text-blue-600 hover:text-blue-800"
                        title="View check image"
                      >
                        <Camera className="h-4 w-4" />
                      </button>
                    )}
                    {payment.notes && <span className="ml-1 text-gray-400">- {payment.notes}</span>}
                  </div>
                  <span className="font-medium">{formatCurrency(payment.amount)}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Info about payment cascading */}
        {remainingBalance > 0 && (
          <div className="bg-blue-50 text-blue-700 p-3 rounded-lg text-sm flex items-start gap-2">
            <AlertCircle className="h-4 w-4 mt-0.5" />
            <div>
              <p className="font-medium">Payment Cascading</p>
              <p>Any overpayment on a stage automatically applies to the next stage. The system prevents payments exceeding the total contract amount.</p>
            </div>
          </div>
        )}
      </CardContent>

      {/* Check Image Modal */}
      {selectedCheckImage && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" onClick={() => setSelectedCheckImage(null)}>
          <div className="bg-white rounded-lg p-4 max-w-4xl max-h-[90vh] overflow-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold">Check Image</h3>
              <button
                onClick={() => setSelectedCheckImage(null)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <img
              src={selectedCheckImage}
              alt="Check"
              className="max-w-full h-auto"
            />
          </div>
        </div>
      )}
    </Card>
  )
}