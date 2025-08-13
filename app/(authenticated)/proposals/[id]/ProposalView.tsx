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
  userId?: string  // Made optional since we don't always need it
}

export default function ProposalView({ proposal, userRole, userId }: ProposalViewProps) {
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
      sent: { color: 'bg-blue-100 text-blue-800', icon: CheckCircleIcon },
      approved: { color: 'bg-green-100 text-green-800', icon: CheckCircleIcon },
      rejected: { color: 'bg-red-100 text-red-800', icon: XCircleIcon },
      paid: { color: 'bg-purple-100 text-purple-800' }
    }

    const config = statusConfig[status] || statusConfig.draft

    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        {config.icon && <config.icon className="w-3 h-3 mr-1" />}
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    )
  }

  const canEdit = (userRole === 'admin' || userRole === 'boss') && 
    (proposal.status === 'draft' || proposal.status === 'sent' || 
     (proposal.status === 'approved' && !proposal.deposit_paid_at))

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8 flex justify-between items-center">
        <div className="flex items-center gap-4">
          <Link
            href="/proposals"
            className="inline-flex items-center text-sm font-medium text-gray-500 hover:text-gray-700"
          >
            <ArrowLeftIcon className="w-4 h-4 mr-1" />
            Back to Proposals
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">
            Proposal {proposal.proposal_number}
          </h1>
          {getStatusBadge(proposal.status)}
        </div>
        
        <div className="flex gap-2">
          {canEdit && (
            <Link href={`/proposals/${proposal.id}/edit`}>
              <button className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                <PencilIcon className="w-4 h-4 mr-2" />
                Edit
              </button>
            </Link>
          )}
          
          {proposal.status === 'draft' && (userRole === 'admin' || userRole === 'boss') && (
            <SendProposal 
              proposalId={proposal.id}
              customerEmail={proposal.customers?.email}
              proposalNumber={proposal.proposal_number}
              onSent={() => router.refresh()}
            />
          )}
          
          <button
            onClick={handlePrint}
            className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            <PrinterIcon className="w-4 h-4 mr-2" />
            Print
          </button>
        </div>
      </div>

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
        
        <div className="border-t border-gray-200 px-4 py-5 sm:px-6">
          <dl className="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
            <div>
              <dt className="text-sm font-medium text-gray-500">Customer</dt>
              <dd className="mt-1 text-sm text-gray-900">
                {proposal.customers?.name || 'No customer assigned'}
              </dd>
            </div>
            
            <div>
              <dt className="text-sm font-medium text-gray-500">Date Created</dt>
              <dd className="mt-1 text-sm text-gray-900">
                {formatDate(proposal.created_at)}
              </dd>
            </div>
            
            <div>
              <dt className="text-sm font-medium text-gray-500">Total Amount</dt>
              <dd className="mt-1 text-sm text-gray-900 font-semibold">
                {formatCurrency(proposal.total || 0)}
              </dd>
            </div>
            
            <div>
              <dt className="text-sm font-medium text-gray-500">Status</dt>
              <dd className="mt-1">
                {getStatusBadge(proposal.status)}
              </dd>
            </div>
          </dl>
        </div>

        {/* Line Items */}
        {proposal.proposal_items && proposal.proposal_items.length > 0 && (
          <div className="border-t border-gray-200">
            <div className="px-4 py-5 sm:px-6">
              <h4 className="text-base font-medium text-gray-900">Line Items</h4>
            </div>
            <div className="overflow-hidden">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Item
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Quantity
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
                    .filter((item: any) => item.is_selected)
                    .map((item: any) => (
                      <tr key={item.id}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {item.name}
                          {item.description && (
                            <p className="text-gray-500">{item.description}</p>
                          )}
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
                <tfoot className="bg-gray-50">
                  <tr>
                    <td colSpan={3} className="px-6 py-4 text-right text-sm font-medium text-gray-900">
                      Subtotal
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {formatCurrency(proposal.subtotal || 0)}
                    </td>
                  </tr>
                  <tr>
                    <td colSpan={3} className="px-6 py-4 text-right text-sm font-medium text-gray-900">
                      Tax ({(proposal.tax_rate * 100).toFixed(0)}%)
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {formatCurrency(proposal.tax_amount || 0)}
                    </td>
                  </tr>
                  <tr>
                    <td colSpan={3} className="px-6 py-4 text-right text-sm font-bold text-gray-900">
                      Total
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900">
                      {formatCurrency(proposal.total || 0)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
