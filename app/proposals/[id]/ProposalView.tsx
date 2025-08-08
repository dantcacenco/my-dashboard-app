'use client'

import { useState, useRef } from 'react'
import { useRouter } from 'next/navigation'
import SendProposal from '@/components/SendProposal'
import { createClient } from '@/lib/supabase/client'
import { PrinterIcon, ArrowLeftIcon, PencilIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline'
import Link from 'next/link'

interface ProposalViewProps {
  proposal: any
  userRole: string
}

export default function ProposalView({ proposal, userRole }: ProposalViewProps) {
  const router = useRouter()
  const [showPrintView, setShowPrintView] = useState(false)
  const printRef = useRef<HTMLDivElement>(null)
  const supabase = createClient()

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    }).format(new Date(dateString))
  }

  const handlePrint = () => {
    setShowPrintView(true)
    setTimeout(() => {
      window.print()
      setShowPrintView(false)
    }, 100)
  }

  const getStatusBadge = (status: string) => {
    const statusConfig: Record<string, { color: string; icon?: any }> = {
      draft: { color: 'bg-gray-100 text-gray-800' },
      sent: { color: 'bg-blue-100 text-blue-800' },
      approved: { color: 'bg-green-100 text-green-800', icon: CheckCircleIcon },
      rejected: { color: 'bg-red-100 text-red-800', icon: XCircleIcon },
      paid: { color: 'bg-purple-100 text-purple-800' }
    }

    const config = statusConfig[status] || statusConfig.draft
    const Icon = config.icon

    return (
      <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-sm font-medium ${config.color}`}>
        {Icon && <Icon className="w-4 h-4" />}
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    )
  }

  const canEdit = proposal.status === 'draft' || 
                  (proposal.status === 'sent' && !proposal.approved_at) ||
                  (userRole === 'admin' || userRole === 'boss')

  // Print view
  if (showPrintView) {
    return (
      <div className="fixed inset-0 bg-white z-50 overflow-auto">
        <div className="max-w-4xl mx-auto p-8" ref={printRef}>
          <style jsx global>{`
            @media print {
              body * { visibility: hidden; }
              #print-content, #print-content * { visibility: visible; }
              #print-content { position: absolute; left: 0; top: 0; }
            }
          `}</style>
          <div id="print-content">
            <div className="mb-8">
              <h1 className="text-3xl font-bold text-gray-900">Service Pro HVAC</h1>
              <p className="text-gray-600">Professional HVAC Services</p>
            </div>
            {/* Rest of print content - simplified for brevity */}
            <div className="mb-6">
              <h2 className="text-xl font-semibold">Proposal #{proposal.proposal_number}</h2>
              <p>Date: {formatDate(proposal.created_at)}</p>
            </div>
          </div>
        </div>
      </div>
    )
  }

  // Regular view
  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="bg-white rounded-lg shadow mb-6">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <Link
                href="/proposals"
                className="inline-flex items-center text-blue-600 hover:text-blue-800"
              >
                <ArrowLeftIcon className="w-4 h-4 mr-1" />
                Back to Proposals
              </Link>
              <div className="flex items-center gap-4">
                {getStatusBadge(proposal.status)}
                {proposal.payment_status && (
                  <span className="text-sm text-gray-600">
                    Payment: {proposal.payment_status}
                  </span>
                )}
              </div>
            </div>

            <div className="flex items-start justify-between">
              <div>
                <h1 className="text-3xl font-bold text-gray-900">
                  Proposal #{proposal.proposal_number}
                </h1>
                <p className="text-gray-600 mt-1">
                  Created on {formatDate(proposal.created_at)}
                </p>
                {proposal.valid_until && (
                  <p className="text-sm text-gray-500 mt-1">
                    Valid until {formatDate(proposal.valid_until)}
                  </p>
                )}
              </div>

              <div className="flex gap-2">
                {canEdit && (
                  <button
                    onClick={() => router.push(`/proposals/${proposal.id}/edit`)}
                    className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                  >
                    <PencilIcon className="w-4 h-4 mr-2" />
                    Edit
                  </button>
                )}
                <button
                  onClick={handlePrint}
                  className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                >
                  <PrinterIcon className="w-4 h-4 mr-2" />
                  Print
                </button>
                {proposal.status !== 'paid' && proposal.status !== 'rejected' && (
                  <SendProposal
                    proposalId={proposal.id}
                    proposalNumber={proposal.proposal_number}
                    customerEmail={proposal.customers?.email}
                    customerName={proposal.customers?.name}
                    onSent={async () => {
                      router.refresh()
                    }}
                  />
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Customer Information */}
        <div className="bg-white rounded-lg shadow mb-6">
          <div className="p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Customer Information</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">Name</p>
                <p className="font-medium">{proposal.customers?.name}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Email</p>
                <p className="font-medium">{proposal.customers?.email}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Phone</p>
                <p className="font-medium">{proposal.customers?.phone}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Address</p>
                <p className="font-medium">{proposal.customers?.address}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Proposal Details */}
        <div className="bg-white rounded-lg shadow mb-6">
          <div className="p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">{proposal.title}</h2>
            {proposal.description && (
              <p className="text-gray-600 whitespace-pre-wrap">{proposal.description}</p>
            )}
          </div>
        </div>

        {/* Line Items */}
        <div className="bg-white rounded-lg shadow mb-6">
          <div className="p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Services</h2>
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
                    <td className="text-right py-3 font-medium">{formatCurrency(proposal.subtotal)}</td>
                  </tr>
                  <tr>
                    <td colSpan={3} className="text-right py-3 font-medium">
                      Tax ({proposal.tax_rate}%):
                    </td>
                    <td className="text-right py-3 font-medium">{formatCurrency(proposal.tax_amount)}</td>
                  </tr>
                  <tr className="border-t">
                    <td colSpan={3} className="text-right py-3 text-xl font-bold">Total:</td>
                    <td className="text-right py-3 text-xl font-bold text-green-600">
                      {formatCurrency(proposal.total)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        </div>

        {/* Payment Status */}
        {proposal.payment_status && (
          <div className="bg-white rounded-lg shadow mb-6">
            <div className="p-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Payment Information</h2>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {proposal.deposit_paid_at && (
                  <div>
                    <p className="text-sm text-gray-600">Deposit Paid</p>
                    <p className="font-medium">{formatCurrency(proposal.deposit_amount || 0)}</p>
                    <p className="text-xs text-gray-500">{formatDate(proposal.deposit_paid_at)}</p>
                  </div>
                )}
                {proposal.progress_paid_at && (
                  <div>
                    <p className="text-sm text-gray-600">Progress Payment</p>
                    <p className="font-medium">{formatCurrency(proposal.progress_payment_amount || 0)}</p>
                    <p className="text-xs text-gray-500">{formatDate(proposal.progress_paid_at)}</p>
                  </div>
                )}
                {proposal.final_paid_at && (
                  <div>
                    <p className="text-sm text-gray-600">Final Payment</p>
                    <p className="font-medium">{formatCurrency(proposal.final_payment_amount || 0)}</p>
                    <p className="text-xs text-gray-500">{formatDate(proposal.final_paid_at)}</p>
                  </div>
                )}
              </div>
              {proposal.total_paid > 0 && (
                <div className="mt-4 pt-4 border-t">
                  <div className="flex justify-between">
                    <span className="font-medium">Total Paid:</span>
                    <span className="font-bold text-green-600">{formatCurrency(proposal.total_paid)}</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
