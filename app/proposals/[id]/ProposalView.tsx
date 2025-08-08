'use client'

import { useState, useRef } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { formatCurrency, formatDate } from '@/lib/utils'
import { PaymentStages } from './PaymentStages'
import SendProposal from '@/components/proposals/SendProposal'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  ArrowLeft, 
  Edit, 
  Printer, 
  Trash2, 
  Send,
  Briefcase,
  CheckCircle,
  XCircle,
  Clock,
  DollarSign,
  FileText
} from 'lucide-react'

interface ProposalViewProps {
  proposal: any
  userRole: string | null
  userId: string
}

export default function ProposalView({ proposal, userRole, userId }: ProposalViewProps) {
  const [showPrintView, setShowPrintView] = useState(false)
  const printRef = useRef<HTMLDivElement>(null)
  const router = useRouter()
  const supabase = createClient()

  // Check if user can edit - both admin and boss roles, and correct status
  const canEdit = (userRole === 'admin' || userRole === 'boss') && 
    (proposal.status === 'draft' || proposal.status === 'sent' || 
     (proposal.status === 'approved' && !proposal.deposit_paid_at))

  // Check if we can create a job (proposal is approved)
  const canCreateJob = (userRole === 'admin' || userRole === 'boss') && 
    proposal.status === 'approved' && !proposal.job_created

  const handlePrint = () => {
    if (typeof window !== 'undefined') {
      window.print()
    }
  }

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this proposal?')) return

    const { error } = await supabase
      .from('proposals')
      .delete()
      .eq('id', proposal.id)

    if (error) {
      console.error('Error deleting proposal:', error)
      alert('Failed to delete proposal')
    } else {
      router.push('/proposals')
    }
  }

  const handleCreateJob = () => {
    // Navigate to job creation with proposal data
    router.push(`/jobs/new?proposal_id=${proposal.id}`)
  }

  const handleProposalSent = (proposalId: string, token: string) => {
    // Reload the page to reflect the updated status
    router.refresh()
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'draft':
        return <FileText className="h-4 w-4" />
      case 'sent':
        return <Send className="h-4 w-4" />
      case 'approved':
        return <CheckCircle className="h-4 w-4" />
      case 'rejected':
        return <XCircle className="h-4 w-4" />
      case 'paid':
        return <DollarSign className="h-4 w-4" />
      default:
        return <Clock className="h-4 w-4" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'approved': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      case 'paid': return 'bg-purple-100 text-purple-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getPaymentProgress = () => {
    if (proposal.payment_status === 'not_started') return null

    return (
      <div className="mt-6">
        <PaymentStages
          depositPaidAt={proposal.deposit_paid_at}
          progressPaidAt={proposal.progress_paid_at}
          finalPaidAt={proposal.final_paid_at}
          depositAmount={proposal.deposit_amount || 0}
          progressAmount={proposal.progress_payment_amount || 0}
          finalAmount={proposal.final_payment_amount || 0}
          currentStage={proposal.current_payment_stage || 'deposit'}
        />
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      {/* Header */}
      <div className="mb-6">
        <Link
          href="/proposals"
          className="inline-flex items-center text-sm text-gray-600 hover:text-gray-900 mb-4"
        >
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back to Proposals
        </Link>

        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-3">
              Proposal #{proposal.proposal_number}
              <Badge className={getStatusColor(proposal.status)}>
                <span className="mr-1">{getStatusIcon(proposal.status)}</span>
                {proposal.status}
              </Badge>
            </h1>
            <p className="mt-1 text-gray-600">
              Created on {formatDate(proposal.created_at)}
            </p>
          </div>

          <div className="flex gap-2">
            {canEdit && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => router.push(`/proposals/${proposal.id}/edit`)}
              >
                <Edit className="h-4 w-4 mr-1" />
                Edit
              </Button>
            )}
            <Button
              variant="outline"
              size="sm"
              onClick={handlePrint}
            >
              <Printer className="h-4 w-4 mr-1" />
              Print
            </Button>
            {(userRole === 'admin' || userRole === 'boss') && 
             (proposal.status === 'draft' || proposal.status === 'sent') && (
              <SendProposal
                proposalId={proposal.id}
                proposalNumber={proposal.proposal_number}
                customerEmail={proposal.customers?.email || ''}
                customerName={proposal.customers?.name}
                currentToken={proposal.customer_view_token}
                onSent={handleProposalSent}
                buttonVariant="default"
                buttonSize="sm"
                buttonText="Send to Customer"
                showIcon={true}
              />
            )}
            {canCreateJob && (
              <Button
                variant="default"
                size="sm"
                onClick={handleCreateJob}
                className="bg-purple-600 hover:bg-purple-700"
              >
                <Briefcase className="h-4 w-4 mr-1" />
                Create Job
              </Button>
            )}
            {(userRole === 'admin' || userRole === 'boss') && (
              <Button
                variant="destructive"
                size="sm"
                onClick={handleDelete}
              >
                <Trash2 className="h-4 w-4 mr-1" />
                Delete
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Payment Progress - Show for approved proposals */}
      {proposal.status === 'approved' && getPaymentProgress()}

      {/* Customer Information */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Customer Information</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Name</p>
              <p className="font-medium">{proposal.customers.name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Email</p>
              <p className="font-medium">{proposal.customers.email}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Phone</p>
              <p className="font-medium">{proposal.customers.phone}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Address</p>
              <p className="font-medium">{proposal.customers.address}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Proposal Details */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>{proposal.title}</CardTitle>
        </CardHeader>
        <CardContent>
          {proposal.description && (
            <p className="text-gray-600 whitespace-pre-wrap">{proposal.description}</p>
          )}
        </CardContent>
      </Card>

      {/* Line Items */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Services</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3">Item</th>
                  <th className="text-center py-3">Quantity</th>
                  <th className="text-right py-3">Unit Price</th>
                  <th className="text-right py-3">Total</th>
                </tr>
              </thead>
              <tbody>
                {proposal.proposal_items?.map((item: any) => (
                  <tr key={item.id} className="border-b">
                    <td className="py-3">
                      <div>
                        <p className="font-medium">{item.name}</p>
                        {item.description && (
                          <p className="text-sm text-gray-600">{item.description}</p>
                        )}
                      </div>
                    </td>
                    <td className="text-center py-3">{item.quantity}</td>
                    <td className="text-right py-3">{formatCurrency(item.unit_price)}</td>
                    <td className="text-right py-3">{formatCurrency(item.total_price)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr>
                  <td colSpan={3} className="text-right py-3 font-medium">Subtotal:</td>
                  <td className="text-right py-3">{formatCurrency(proposal.subtotal)}</td>
                </tr>
                {proposal.tax_amount > 0 && (
                  <tr>
                    <td colSpan={3} className="text-right py-3 font-medium">
                      Tax ({proposal.tax_rate}%):
                    </td>
                    <td className="text-right py-3">{formatCurrency(proposal.tax_amount)}</td>
                  </tr>
                )}
                <tr className="border-t">
                  <td colSpan={3} className="text-right py-3 text-lg font-bold">Total:</td>
                  <td className="text-right py-3 text-lg font-bold">
                    {formatCurrency(proposal.total)}
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Signature Section */}
      {proposal.signed_at && proposal.signature_data && (
        <Card>
          <CardHeader>
            <CardTitle>Customer Approval</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <p className="text-sm text-gray-600">Approved by</p>
                <p className="font-medium">{proposal.signature_data}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Approved on</p>
                <p className="font-medium">{formatDate(proposal.signed_at)}</p>
              </div>
              {proposal.customer_notes && (
                <div>
                  <p className="text-sm text-gray-600">Customer Notes</p>
                  <p className="font-medium">{proposal.customer_notes}</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
