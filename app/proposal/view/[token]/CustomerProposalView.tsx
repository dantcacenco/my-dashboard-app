'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { CheckCircle, XCircle, Clock, DollarSign } from 'lucide-react'
import { useRouter } from 'next/navigation'

interface CustomerProposalViewProps {
  proposal: any
  token: string
}

export default function CustomerProposalView({ proposal, token }: CustomerProposalViewProps) {
  const [isApproving, setIsApproving] = useState(false)
  const [isRejecting, setIsRejecting] = useState(false)
  const [rejectionReason, setRejectionReason] = useState('')
  const [showRejectionForm, setShowRejectionForm] = useState(false)
  const [paymentStages, setPaymentStages] = useState<any[]>([])
  const [isProcessingPayment, setIsProcessingPayment] = useState(false)
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    if (proposal.status === 'approved') {
      calculatePaymentStages()
    }
  }, [proposal])

  const calculatePaymentStages = () => {
    const stages = [
      {
        name: 'Deposit',
        percentage: 50,
        amount: proposal.total * 0.5,
        status: proposal.deposit_paid_at ? 'paid' : 'pending',
        paid_at: proposal.deposit_paid_at
      },
      {
        name: 'Rough In',
        percentage: 30,
        amount: proposal.total * 0.3,
        status: proposal.progress_paid_at ? 'paid' : (proposal.deposit_paid_at ? 'pending' : 'locked'),
        paid_at: proposal.progress_paid_at
      },
      {
        name: 'Final',
        percentage: 20,
        amount: proposal.total * 0.2,
        status: proposal.final_paid_at ? 'paid' : (proposal.progress_paid_at ? 'pending' : 'locked'),
        paid_at: proposal.final_paid_at
      }
    ]
    setPaymentStages(stages)
  }

  const handleApprove = async () => {
    try {
      setIsApproving(true)
      
      // Use fetch API for better Android compatibility
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId: proposal.id,
          action: 'approve',
          token: token
        })
      })

      const data = await response.json()
      
      if (!response.ok) {
        throw new Error(data.error || 'Failed to approve proposal')
      }

      // Force reload to show updated status
      window.location.reload()
    } catch (error: any) {
      console.error('Approval error:', error)
      alert(error.message || 'Failed to approve proposal. Please try again.')
    } finally {
      setIsApproving(false)
    }
  }

  const handleReject = async () => {
    if (!rejectionReason.trim()) {
      alert('Please provide a reason for rejection')
      return
    }

    try {
      setIsRejecting(true)
      
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId: proposal.id,
          action: 'reject',
          reason: rejectionReason,
          token: token
        })
      })

      const data = await response.json()
      
      if (!response.ok) {
        throw new Error(data.error || 'Failed to reject proposal')
      }

      window.location.reload()
    } catch (error: any) {
      console.error('Rejection error:', error)
      alert(error.message || 'Failed to reject proposal. Please try again.')
    } finally {
      setIsRejecting(false)
    }
  }

  const handlePayment = async (stage: string) => {
    try {
      setIsProcessingPayment(true)
      
      // Determine payment amount based on stage
      let amount = 0
      if (stage === 'deposit') amount = proposal.total * 0.5
      else if (stage === 'roughin') amount = proposal.total * 0.3
      else if (stage === 'final') amount = proposal.total * 0.2

      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId: proposal.id,
          amount: amount,
          paymentStage: stage,
          customerEmail: proposal.customers?.email,
          useStripe: false // Use Bill.com by default
        })
      })

      const data = await response.json()
      
      if (!response.ok) {
        throw new Error(data.error || 'Payment initialization failed')
      }

      // Redirect to payment URL
      if (data.paymentUrl) {
        window.location.href = data.paymentUrl
      } else {
        throw new Error('No payment URL received')
      }
    } catch (error: any) {
      console.error('Payment error:', error)
      alert(error.message || 'Failed to process payment. Please try again.')
    } finally {
      setIsProcessingPayment(false)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">
            Proposal #{proposal.proposal_number}
          </h1>
          <p className="mt-2 text-gray-600">
            From {proposal.customers?.name || 'Your HVAC Company'}
          </p>
        </div>

        {/* Status Banner */}
        {proposal.status === 'approved' && (
          <div className="mb-6 bg-green-50 border border-green-200 rounded-lg p-4">
            <div className="flex items-center">
              <CheckCircle className="h-5 w-5 text-green-600 mr-2" />
              <span className="text-green-800 font-medium">
                This proposal has been approved
              </span>
            </div>
          </div>
        )}

        {proposal.status === 'rejected' && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
            <div className="flex items-center">
              <XCircle className="h-5 w-5 text-red-600 mr-2" />
              <span className="text-red-800 font-medium">
                This proposal has been rejected
              </span>
            </div>
            {proposal.customer_notes && (
              <p className="mt-2 text-red-700 text-sm">
                Reason: {proposal.customer_notes}
              </p>
            )}
          </div>
        )}

        {/* Proposal Details */}
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>{proposal.title}</CardTitle>
          </CardHeader>
          <CardContent>
            {proposal.description && (
              <p className="text-gray-600 mb-4">{proposal.description}</p>
            )}
            
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-gray-500">Valid Until:</span>
                <span className="ml-2 font-medium">
                  {proposal.valid_until ? formatDate(proposal.valid_until) : 'No expiration'}
                </span>
              </div>
              <div>
                <span className="text-gray-500">Total Amount:</span>
                <span className="ml-2 font-medium text-lg text-green-600">
                  {formatCurrency(proposal.total)}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Line Items */}
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>Services & Materials</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-2">Item</th>
                    <th className="text-center py-2">Qty</th>
                    <th className="text-right py-2">Price</th>
                    <th className="text-right py-2">Total</th>
                  </tr>
                </thead>
                <tbody>
                  {proposal.proposal_items?.map((item: any) => (
                    <tr key={item.id} className="border-b">
                      <td className="py-2">
                        <div>
                          <p className="font-medium">{item.name}</p>
                          {item.description && (
                            <p className="text-sm text-gray-500">{item.description}</p>
                          )}
                        </div>
                      </td>
                      <td className="text-center py-2">{item.quantity}</td>
                      <td className="text-right py-2">
                        {formatCurrency(item.unit_price)}
                      </td>
                      <td className="text-right py-2 font-medium">
                        {formatCurrency(item.total_price)}
                      </td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr>
                    <td colSpan={3} className="text-right py-3 font-medium">
                      Subtotal:
                    </td>
                    <td className="text-right py-3 font-medium">
                      {formatCurrency(proposal.subtotal)}
                    </td>
                  </tr>
                  {proposal.tax_amount > 0 && (
                    <tr>
                      <td colSpan={3} className="text-right py-2">
                        Tax ({proposal.tax_rate}%):
                      </td>
                      <td className="text-right py-2">
                        {formatCurrency(proposal.tax_amount)}
                      </td>
                    </tr>
                  )}
                  <tr className="border-t">
                    <td colSpan={3} className="text-right py-3 text-lg font-bold">
                      Total:
                    </td>
                    <td className="text-right py-3 text-lg font-bold text-green-600">
                      {formatCurrency(proposal.total)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </CardContent>
        </Card>

        {/* Approval/Rejection Actions */}
        {proposal.status === 'sent' && (
          <Card className="mb-6">
            <CardHeader>
              <CardTitle>Your Decision</CardTitle>
            </CardHeader>
            <CardContent>
              {!showRejectionForm ? (
                <div className="flex gap-4">
                  <Button
                    onClick={handleApprove}
                    disabled={isApproving}
                    className="flex-1 bg-green-600 hover:bg-green-700"
                    size="lg"
                  >
                    {isApproving ? (
                      <>
                        <Clock className="mr-2 h-4 w-4 animate-spin" />
                        Processing...
                      </>
                    ) : (
                      <>
                        <CheckCircle className="mr-2 h-4 w-4" />
                        Approve Proposal
                      </>
                    )}
                  </Button>
                  <Button
                    onClick={() => setShowRejectionForm(true)}
                    variant="outline"
                    className="flex-1 border-red-600 text-red-600 hover:bg-red-50"
                    size="lg"
                  >
                    <XCircle className="mr-2 h-4 w-4" />
                    Reject Proposal
                  </Button>
                </div>
              ) : (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Reason for rejection (optional)
                    </label>
                    <textarea
                      value={rejectionReason}
                      onChange={(e) => setRejectionReason(e.target.value)}
                      className="w-full p-3 border rounded-lg"
                      rows={3}
                      placeholder="Please let us know why you're rejecting this proposal..."
                    />
                  </div>
                  <div className="flex gap-4">
                    <Button
                      onClick={handleReject}
                      disabled={isRejecting}
                      className="flex-1 bg-red-600 hover:bg-red-700"
                    >
                      {isRejecting ? 'Processing...' : 'Confirm Rejection'}
                    </Button>
                    <Button
                      onClick={() => {
                        setShowRejectionForm(false)
                        setRejectionReason('')
                      }}
                      variant="outline"
                      className="flex-1"
                    >
                      Cancel
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {/* Payment Stages */}
        {proposal.status === 'approved' && paymentStages.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>Payment Schedule</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {paymentStages.map((stage, index) => (
                  <div
                    key={index}
                    className={`border rounded-lg p-4 ${
                      stage.status === 'paid'
                        ? 'bg-green-50 border-green-200'
                        : stage.status === 'locked'
                        ? 'bg-gray-50 border-gray-200'
                        : 'bg-blue-50 border-blue-200'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-semibold">
                          {stage.name} ({stage.percentage}%)
                        </h4>
                        <p className="text-2xl font-bold mt-1">
                          {formatCurrency(stage.amount)}
                        </p>
                        {stage.paid_at && (
                          <p className="text-sm text-gray-600 mt-1">
                            Paid on {formatDate(stage.paid_at)}
                          </p>
                        )}
                      </div>
                      <div>
                        {stage.status === 'paid' ? (
                          <div className="flex items-center text-green-600">
                            <CheckCircle className="h-5 w-5 mr-2" />
                            <span className="font-medium">Paid</span>
                          </div>
                        ) : stage.status === 'locked' ? (
                          <div className="flex items-center text-gray-400">
                            <Clock className="h-5 w-5 mr-2" />
                            <span>Locked</span>
                          </div>
                        ) : (
                          <Button
                            onClick={() => handlePayment(stage.name.toLowerCase().replace(' ', ''))}
                            disabled={isProcessingPayment}
                            className="bg-blue-600 hover:bg-blue-700"
                          >
                            {isProcessingPayment ? (
                              <>
                                <Clock className="mr-2 h-4 w-4 animate-spin" />
                                Processing...
                              </>
                            ) : (
                              <>
                                <DollarSign className="mr-2 h-4 w-4" />
                                Pay Now
                              </>
                            )}
                          </Button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              
              {/* Progress Bar */}
              <div className="mt-6">
                <div className="flex justify-between text-sm text-gray-600 mb-2">
                  <span>Payment Progress</span>
                  <span>{proposal.total_paid ? Math.round((proposal.total_paid / proposal.total) * 100) : 0}%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-3">
                  <div
                    className="bg-green-600 h-3 rounded-full transition-all"
                    style={{
                      width: `${proposal.total_paid ? (proposal.total_paid / proposal.total) * 100 : 0}%`
                    }}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}
