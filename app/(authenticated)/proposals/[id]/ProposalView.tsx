'use client'

import { useState, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Printer, Send, Edit, ChevronLeft, Plus, Link2, Check } from 'lucide-react'
import Link from 'next/link'
import { PaymentStages } from './PaymentStages'
import SendProposal from './SendProposal'
import CreateJobModal from './CreateJobModal'
import RecordManualPayment from '@/components/RecordManualPayment'
import PaymentBalance from '@/components/PaymentBalance'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'

interface ProposalViewProps {
  proposal: any
  userRole: string
}

export default function ProposalView({ proposal, userRole }: ProposalViewProps) {
  const printRef = useRef<HTMLDivElement>(null)
  const [showPrintView, setShowPrintView] = useState(false)
  const [showSendModal, setShowSendModal] = useState(false)
  const [showCreateJobModal, setShowCreateJobModal] = useState(false)
  const [showRecordPayment, setShowRecordPayment] = useState(false)
  const [showCopiedTooltip, setShowCopiedTooltip] = useState(false)
  const router = useRouter()

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-500'
      case 'sent': return 'bg-blue-500'
      case 'viewed': return 'bg-purple-500'
      case 'approved':
      case 'accepted': return 'bg-green-500'
      case 'rejected': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  const handlePrint = () => {
    setShowPrintView(true)
    setTimeout(() => {
      window.print()
      setShowPrintView(false)
    }, 100)
  }

  const handleSendSuccess = () => {
    toast.success('Proposal sent successfully!')
    router.refresh()
  }

  const handleCopyCustomerLink = () => {
    const customerUrl = `${window.location.origin}/proposal/view/${proposal.customer_view_token}`
    navigator.clipboard.writeText(customerUrl)
    setShowCopiedTooltip(true)
    setTimeout(() => setShowCopiedTooltip(false), 2000)
  }

  // Check if a job can be created (no existing job for this proposal)
  const canCreateJob = !proposal.has_existing_job

  // Show admin controls for boss or admin roles
  const isAdmin = userRole === 'admin' || userRole === 'boss'
  
  return (
    <div className="space-y-6">
      {/* Action Buttons for Admin/Boss */}
      {isAdmin && (
        <div className="flex justify-between mb-6">
          <Button onClick={() => router.back()} variant="outline" size="sm">
            <ChevronLeft className="h-4 w-4 mr-1" />
            Back
          </Button>
          <div className="flex gap-2">
            <Link href={`/proposals/${proposal.id}/edit`}>
              <Button variant="outline" size="sm">
                <Edit className="h-4 w-4 mr-1" />
                Edit
              </Button>
            </Link>
            <Button 
              onClick={() => setShowSendModal(true)} 
              variant="outline" 
              size="sm"
              disabled={!proposal.customers?.email}
            >
              <Send className="h-4 w-4 mr-1" />
              Send to Customer
            </Button>
            <Button onClick={handlePrint} variant="outline" size="sm">
              <Printer className="h-4 w-4 mr-1" />
              Print
            </Button>
            <div className="relative">
              <Button 
                onClick={handleCopyCustomerLink} 
                variant="outline" 
                size="sm"
              >
                <Link2 className="h-4 w-4 mr-1" />
                Customer Link
              </Button>
              {showCopiedTooltip && (
                <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 bg-gray-800 text-white text-xs px-2 py-1 rounded whitespace-nowrap animate-fade-in-out">
                  Copied to clipboard
                </div>
              )}
            </div>
            <Button 
              onClick={() => setShowCreateJobModal(true)} 
              variant="default" 
              size="sm"
              disabled={!canCreateJob}
              title={!canCreateJob ? "A job already exists for this proposal" : ""}
            >
              <Plus className="h-4 w-4 mr-1" />
              Create Job
            </Button>
          </div>
        </div>
      )}

      {/* Status Badge */}
      <div>
        <Badge className={`${getStatusColor(proposal.status)} text-white`}>
          {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
        </Badge>
        {proposal.sent_at && (
          <span className="ml-2 text-sm text-gray-500">
            Sent on {formatDate(proposal.sent_at)}
          </span>
        )}
      </div>

      {/* Proposal Details */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Proposal Details</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div>
              <p className="text-sm text-gray-500">Proposal Title</p>
              <p className="font-medium">{proposal.title || 'Untitled Proposal'}</p>
            </div>
            {proposal.description && (
              <div>
                <p className="text-sm text-gray-500">Description</p>
                <p className="text-gray-700 whitespace-pre-wrap">{proposal.description}</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Customer Information */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Customer Information</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <div>
              <p className="text-sm text-gray-500">Name</p>
              <p className="font-medium">{proposal.customers?.name || 'No customer'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Email</p>
              <p className="font-medium">{proposal.customers?.email || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Phone</p>
              <p className="font-medium">{proposal.customers?.phone || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Address</p>
              <p className="font-medium">{proposal.customers?.address || '-'}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Services */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Services</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {proposal.proposal_items?.filter((item: any) => !item.is_addon).map((item: any) => (
              <div key={item.id} className="flex justify-between items-start">
                <div className="flex-1">
                  <h4 className="font-medium">{item.name}</h4>
                  {item.description && (
                    <p className="text-sm text-gray-600">{item.description}</p>
                  )}
                  <p className="text-sm text-gray-500">Qty: {item.quantity} × {formatCurrency(item.unit_price)}</p>
                </div>
                <p className="font-medium">{formatCurrency(item.total_price)}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Optional Add-ons */}
      {proposal.proposal_items?.some((item: any) => item.is_addon) && (
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>Optional Add-ons</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {proposal.proposal_items.filter((item: any) => item.is_addon).map((item: any) => (
                <div key={item.id} className="flex justify-between items-start">
                  <div className="flex-1">
                    <h4 className="font-medium">{item.name}</h4>
                    {item.description && (
                      <p className="text-sm text-gray-600">{item.description}</p>
                    )}
                    <p className="text-sm text-gray-500">Qty: {item.quantity} × {formatCurrency(item.unit_price)}</p>
                  </div>
                  <p className="font-medium">{formatCurrency(item.total_price)}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Totals */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Totals</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span>Subtotal:</span>
              <span>{formatCurrency(proposal.subtotal || 0)}</span>
            </div>
            <div className="flex justify-between">
              <span>Tax ({((proposal.tax_rate || 0) * 100).toFixed(1)}%):</span>
              <span>{formatCurrency(proposal.tax_amount || 0)}</span>
            </div>
            <div className="flex justify-between font-bold text-lg border-t pt-2">
              <span>Total:</span>
              <span>{formatCurrency(proposal.total || 0)}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Payment Balance - Show for approved proposals with detailed payment tracking */}
      {(proposal.status === 'approved' || proposal.status === 'deposit paid' || 
        proposal.status === 'rough-in paid' || proposal.status === 'final paid' || 
        proposal.status === 'completed') && (
        <PaymentBalance
          proposalId={proposal.id}
          depositAmount={proposal.deposit_amount || proposal.total * 0.5}
          progressAmount={proposal.progress_payment_amount || proposal.total * 0.3}
          finalAmount={proposal.final_payment_amount || proposal.total * 0.2}
          total={proposal.total}
          onRecordPayment={() => setShowRecordPayment(true)}
        />
      )}

      {/* Send Proposal Modal */}
      {showSendModal && (
        <SendProposal
          proposalId={proposal.id}
          proposalNumber={proposal.proposal_number}
          customerEmail={proposal.customers?.email}
          customerName={proposal.customers?.name}
          total={proposal.total}
          onClose={() => setShowSendModal(false)}
          onSuccess={handleSendSuccess}
        />
      )}

      {/* Create Job Modal */}
      {showCreateJobModal && (
        <CreateJobModal
          proposal={proposal}
          isOpen={showCreateJobModal}
          onClose={() => setShowCreateJobModal(false)}
        />
      )}

      {/* Record Manual Payment Modal */}
      {showRecordPayment && (
        <RecordManualPayment
          proposalId={proposal.id}
          proposalNumber={proposal.proposal_number}
          depositAmount={proposal.deposit_amount || proposal.total * 0.5}
          progressAmount={proposal.progress_payment_amount || proposal.total * 0.3}
          finalAmount={proposal.final_payment_amount || proposal.total * 0.2}
          totalAmount={proposal.total}
          totalPaid={proposal.total_paid || 0}
          onClose={() => setShowRecordPayment(false)}
          onSuccess={() => {
            toast.success('Payment recorded successfully!')
            router.refresh()
            setShowRecordPayment(false)
          }}
        />
      )}
    </div>
  )
}
