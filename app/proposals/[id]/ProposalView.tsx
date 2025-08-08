'use client'

import { useState, useRef, useEffect } from 'react'
import Link from 'next/link'
import SendProposal from '@/components/proposals/SendProposal'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { formatCurrency, formatDate } from '@/lib/utils'
import { PaymentStages } from './PaymentStages'

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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'approved': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
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

  // Print view
  if (showPrintView) {
    return (
      <div className="fixed inset-0 bg-white z-50 overflow-auto">
        <div className="max-w-4xl mx-auto p-8" ref={printRef}>
          <style jsx global>{`
            @media print {
              @page { margin: 0.5in; }
              .no-print { display: none !important; }
            }
          `}</style>
          
          {/* Print Header */}
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold">Service Pro HVAC</h1>
            <p className="text-gray-600">Professional HVAC Services</p>
          </div>

          {/* Proposal Info */}
          <div className="mb-6">
            <h2 className="text-2xl font-semibold mb-2">Proposal #{proposal.proposal_number}</h2>
            <p className="text-gray-600">Date: {formatDate(proposal.created_at)}</p>
          </div>

          {/* Customer Info */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-2">Customer Information</h3>
            <p>{proposal.customers.name}</p>
            <p>{proposal.customers.email}</p>
            <p>{proposal.customers.phone}</p>
            {proposal.customers.address && <p>{proposal.customers.address}</p>}
          </div>

          {/* Proposal Details */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-2">{proposal.title}</h3>
            {proposal.description && (
              <p className="text-gray-700 mb-4">{proposal.description}</p>
            )}
          </div>

          {/* Items */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-2">Services & Items</h3>
            <table className="w-full border-collapse">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-2">Item</th>
                  <th className="text-right py-2">Qty</th>
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
                          <p className="text-sm text-gray-600">{item.description}</p>
                        )}
                      </div>
                    </td>
                    <td className="text-right py-2">{item.quantity}</td>
                    <td className="text-right py-2">{formatCurrency(item.unit_price)}</td>
                    <td className="text-right py-2">{formatCurrency(item.total_price)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="font-semibold">
                  <td colSpan={3} className="text-right py-2">Total:</td>
                  <td className="text-right py-2">{formatCurrency(proposal.total)}</td>
                </tr>
              </tfoot>
            </table>
          </div>

          {/* Terms */}
          {proposal.terms_conditions && (
            <div className="mb-6">
              <h3 className="text-lg font-semibold mb-2">Terms & Conditions</h3>
              <p className="text-sm text-gray-700 whitespace-pre-wrap">{proposal.terms_conditions}</p>
            </div>
          )}

          {/* Print Actions */}
          <div className="no-print mt-8 flex gap-4">
            <button
              onClick={handlePrint}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Print
            </button>
            <button
              onClick={() => setShowPrintView(false)}
              className="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
            >
              Close Print View
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="mb-6 flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Proposal #{proposal.proposal_number}</h1>
          <p className="text-gray-600">Created on {formatDate(proposal.created_at)}</p>
        </div>
        <div className="flex items-center gap-4">
          <span className={`px-3 py-1 rounded-full text-sm font-semibold ${getStatusColor(proposal.status)}`}>
            {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
          </span>
          {(userRole === 'admin' || userRole === 'boss') && (
            <div className="flex gap-2">
              {proposal.status === 'draft' && (
                <button
                  onClick={() => setShowSendModal(true)}
                  className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
                >
                  Send Proposal
                </button>
              )}
              {canEdit && (
                <Link
                  href={`/proposals/${proposal.id}/edit`}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Edit
                </Link>
              )}
              <button
                onClick={() => setShowPrintView(true)}
                className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
              >
                Print
              </button>
              <button
                onClick={handleDelete}
                className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
              >
                Delete
              </button>
            </div>
          )}
        </div>
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
                <div className="text-gray-600">
                  <p>{proposal.customers.email}</p>
                  <p>{proposal.customers.phone}</p>
                </div>
              </dd>
            </div>
            <div className="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt className="text-sm font-medium text-gray-500">Total Amount</dt>
              <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                {formatCurrency(proposal.total)}
              </dd>
            </div>
            {proposal.payment_status !== 'not_started' && (
              <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Payment Status</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    proposal.payment_status === 'fully_paid' 
                      ? 'bg-green-100 text-green-800' 
                      : 'bg-yellow-100 text-yellow-800'
                  }`}>
                    {proposal.payment_status.replace(/_/g, ' ').charAt(0).toUpperCase() + 
                     proposal.payment_status.replace(/_/g, ' ').slice(1)}
                  </span>
                </dd>
              </div>
            )}
            {proposal.customer_view_token && (
              <div className="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt className="text-sm font-medium text-gray-500">Customer Link</dt>
                <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <a 
                    href={`${window.location.origin}/proposal/view/${proposal.customer_view_token}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:text-blue-900 underline"
                  >
                    View Customer Portal
                  </a>
                </dd>
              </div>
            )}
          </dl>
        </div>
      </div>

      {/* Items Table */}
      <div className="mt-6 bg-white shadow overflow-hidden sm:rounded-lg">
        <div className="px-4 py-5 sm:px-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900">
            Services & Items
          </h3>
        </div>
        <div className="border-t border-gray-200">
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
              {proposal.proposal_items?.map((item: any) => (
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
            <tfoot>
              <tr>
                <th colSpan={3} className="px-6 py-4 text-right text-sm font-medium text-gray-900">
                  Total:
                </th>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900">
                  {formatCurrency(proposal.total)}
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      {/* Terms & Conditions */}
      {proposal.terms_conditions && (
        <div className="mt-6 bg-white shadow overflow-hidden sm:rounded-lg">
          <div className="px-4 py-5 sm:px-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">
              Terms & Conditions
            </h3>
          </div>
          <div className="border-t border-gray-200 px-4 py-5">
            <p className="text-sm text-gray-700 whitespace-pre-wrap">
              {proposal.terms_conditions}
            </p>
          </div>
        </div>
      )}

      {/* Send Proposal Modal */}
      {showSendModal && (
        <SendProposal proposalId={proposal.id} customerEmail={proposal.customers.email} proposalNumber={proposal.proposal_number} currentToken={proposal.customer_view_token} onSent={(id, token) => { setShowSendModal(false); window.location.reload(); }}
        />
      )}
    </div>
  )
}
