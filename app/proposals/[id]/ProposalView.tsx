'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import SendProposal from '@/app/components/SendProposal'

interface ProposalViewProps {
  proposal: any
  userRole?: string
}

export default function ProposalView({ proposal, userRole }: ProposalViewProps) {
  const router = useRouter()
  const [isDeleting, setIsDeleting] = useState(false)
  const [showSendModal, setShowSendModal] = useState(false)
  const supabase = createClient()

  // Check if user can edit (boss or admin)
  const canEdit = userRole === 'admin' || userRole === 'boss'

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this proposal?')) {
      return
    }

    setIsDeleting(true)
    try {
      const { error } = await supabase
        .from('proposals')
        .delete()
        .eq('id', proposal.id)

      if (error) throw error

      router.push('/proposals')
    } catch (error) {
      console.error('Error deleting proposal:', error)
      alert('Failed to delete proposal')
    } finally {
      setIsDeleting(false)
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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft':
        return 'bg-gray-100 text-gray-800'
      case 'sent':
        return 'bg-blue-100 text-blue-800'
      case 'approved':
        return 'bg-green-100 text-green-800'
      case 'rejected':
        return 'bg-red-100 text-red-800'
      case 'paid':
        return 'bg-purple-100 text-purple-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  // Get payment progress for approved proposals
  const getPaymentProgress = () => {
    if (proposal.status !== 'approved') return null

    const totalPaid = (proposal.deposit_amount || 0) + 
                      (proposal.progress_payment_amount || 0) + 
                      (proposal.final_payment_amount || 0)
    const paidPercentage = proposal.total > 0 ? (totalPaid / proposal.total) * 100 : 0

    return (
      <div className="bg-white shadow-sm rounded-lg p-6 mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Payment Progress</h3>
        <div className="mb-4">
          <div className="flex justify-between text-sm text-gray-600 mb-2">
            <span>Total Progress</span>
            <span>{formatCurrency(totalPaid)} of {formatCurrency(proposal.total)} ({paidPercentage.toFixed(0)}%)</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div 
              className="bg-green-600 h-3 rounded-full transition-all duration-300"
              style={{ width: `${paidPercentage}%` }}
            />
          </div>
        </div>
        
        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span>Deposit (50%)</span>
            <span className={proposal.deposit_paid_at ? 'text-green-600' : 'text-gray-500'}>
              {proposal.deposit_paid_at ? `Paid ${formatCurrency(proposal.deposit_amount || 0)}` : 'Pending'}
            </span>
          </div>
          <div className="flex justify-between">
            <span>Rough In (30%)</span>
            <span className={proposal.progress_paid_at ? 'text-green-600' : 'text-gray-500'}>
              {proposal.progress_paid_at ? `Paid ${formatCurrency(proposal.progress_payment_amount || 0)}` : 'Pending'}
            </span>
          </div>
          <div className="flex justify-between">
            <span>Final (20%)</span>
            <span className={proposal.final_paid_at ? 'text-green-600' : 'text-gray-500'}>
              {proposal.final_paid_at ? `Paid ${formatCurrency(proposal.final_payment_amount || 0)}` : 'Pending'}
            </span>
          </div>
        </div>
      </div>
    )
  }

  return (
    <>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header with Actions */}
        <div className="mb-6 flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              Proposal #{proposal.proposal_number}
            </h1>
            <p className="mt-1 text-sm text-gray-600">
              Created on {formatDate(proposal.created_at)}
            </p>
          </div>
          
          {/* Action Buttons - Show for boss/admin only */}
          {canEdit && (
            <div className="flex space-x-3">
              {/* Send to Customer Button - Only show if not already sent/approved/rejected */}
              {(proposal.status === 'draft' || !proposal.sent_at) && (
                <button
                  onClick={() => setShowSendModal(true)}
                  className="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                >
                  Send to Customer
                </button>
              )}
              
              {/* Edit Button - Only show for draft proposals */}
              {proposal.status === 'draft' && (
                <Link
                  href={`/proposals/${proposal.id}/edit`}
                  className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  Edit
                </Link>
              )}
              
              {/* Print Button */}
              <button
                onClick={() => window.print()}
                className="bg-gray-600 text-white px-4 py-2 rounded-md hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
              >
                Print
              </button>
              
              {/* Delete Button */}
              <button
                onClick={handleDelete}
                disabled={isDeleting}
                className="bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:bg-gray-400"
              >
                {isDeleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          )}
        </div>

        {/* Status Badge */}
        <div className="mb-6">
          <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(proposal.status)}`}>
            {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
          </span>
        </div>

        {/* Payment Progress - Show for approved proposals */}
        {proposal.status === 'approved' && getPaymentProgress()}

        {/* Proposal Details */}
        <div className="bg-white shadow overflow-hidden sm:rounded-lg">
          <div className="px-4 py-5 sm:px-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">
              {proposal.title}
            </h3>
            {proposal.description && (
              <p className="mt-1 max-w-2xl text-sm text-gray-500">
                {proposal.description}
              </p>
            )}
          </div>
          <div className="border-t border-gray-200">
            <dl>
              <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Customer</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <Link href={`/customers/${proposal.customers.id}`} className="text-blue-600 hover:text-blue-900">
                    {proposal.customers.name}
                  </Link>
                  <p className="text-gray-500">{proposal.customers.email}</p>
                  <p className="text-gray-500">{proposal.customers.phone}</p>
                </dd>
              </div>
              <div className="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Status Timeline</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <p>Created: {formatDate(proposal.created_at)}</p>
                  {proposal.sent_at && <p>Sent: {formatDate(proposal.sent_at)}</p>}
                  {proposal.approved_at && <p>Approved: {formatDate(proposal.approved_at)}</p>}
                  {proposal.rejected_at && <p>Rejected: {formatDate(proposal.rejected_at)}</p>}
                  {proposal.signed_at && (
                    <p>Signed by: {proposal.signature_data} on {formatDate(proposal.signed_at)}</p>
                  )}
                </dd>
              </div>
              {proposal.customer_notes && (
                <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt className="text-sm font-medium text-gray-500">Customer Notes</dt>
                  <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    {proposal.customer_notes}
                  </dd>
                </div>
              )}
              <div className="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Valid Until</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  {proposal.valid_until ? formatDate(proposal.valid_until) : 'No expiration'}
                </dd>
              </div>
              {proposal.customer_view_token && (
                <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt className="text-sm font-medium text-gray-500">Customer Link</dt>
                  <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    <a 
                      href={`${window.location.origin}/proposal/view/${proposal.customer_view_token}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:text-blue-900 break-all"
                    >
                      {`${window.location.origin}/proposal/view/${proposal.customer_view_token}`}
                    </a>
                  </dd>
                </div>
              )}
            </dl>
          </div>
        </div>

        {/* Items */}
        <div className="mt-8">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Items & Services</h3>
          <div className="bg-white shadow overflow-hidden sm:rounded-lg">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Item
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Qty
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Unit Price
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {proposal.proposal_items
                  ?.filter((item: any) => !item.is_addon)
                  .map((item: any) => (
                    <tr key={item.id}>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div>
                          <div className="text-sm font-medium text-gray-900">{item.name}</div>
                          {item.description && (
                            <div className="text-sm text-gray-500">{item.description}</div>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {item.quantity}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {formatCurrency(item.unit_price)}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {formatCurrency(item.total_price)}
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Add-ons */}
        {proposal.proposal_items?.some((item: any) => item.is_addon) && (
          <div className="mt-8">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Optional Add-ons</h3>
            <div className="bg-white shadow overflow-hidden sm:rounded-lg">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Add-on
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Selected
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Price
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {proposal.proposal_items
                    ?.filter((item: any) => item.is_addon)
                    .map((item: any) => (
                      <tr key={item.id}>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div>
                            <div className="text-sm font-medium text-gray-900">{item.name}</div>
                            {item.description && (
                              <div className="text-sm text-gray-500">{item.description}</div>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {item.is_selected ? 'Yes' : 'No'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {formatCurrency(item.total_price)}
                        </td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Total */}
        <div className="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
          <div className="px-4 py-5 sm:px-6">
            <div className="flex justify-between items-center">
              <h3 className="text-lg font-medium text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-gray-900">{formatCurrency(proposal.total)}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Send Proposal Modal */}
      {showSendModal && (
        <SendProposal
          proposalId={proposal.id}
          proposalNumber={proposal.proposal_number}
          customer={proposal.customers}
          total={proposal.total}
          onClose={() => setShowSendModal(false)}
          onSent={() => {
            setShowSendModal(false)
            router.refresh()
          }}
        />
      )}
    </>
  )
}
