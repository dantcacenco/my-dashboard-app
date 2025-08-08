'use client'

import { useState } from 'react'
import Link from 'next/link'
import { EyeIcon, PencilIcon, PaperAirplaneIcon } from '@heroicons/react/24/outline'
import { Squares2X2Icon, ListBulletIcon } from '@heroicons/react/24/solid'
import SendProposal from '@/components/SendProposal'

interface ProposalListProps {
  proposals: any[]
}

export default function ProposalsList({ proposals }: ProposalListProps) {
  const [viewMode, setViewMode] = useState<'box' | 'list'>('box')

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    }).format(new Date(dateString))
  }

  const getStatusBadge = (status: string) => {
    const statusColors: Record<string, string> = {
      draft: 'bg-gray-100 text-gray-800',
      sent: 'bg-blue-100 text-blue-800',
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      paid: 'bg-purple-100 text-purple-800'
    }
    
    return (
      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${statusColors[status] || statusColors.draft}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    )
  }

  if (viewMode === 'list') {
    return (
      <div>
        <div className="flex justify-end mb-4">
          <div className="flex gap-2">
            <button
              onClick={() => setViewMode('box')}
              className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded"
              title="Box View"
            >
              <Squares2X2Icon className="h-5 w-5" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className="p-2 text-gray-900 bg-gray-100 rounded"
              title="List View"
            >
              <ListBulletIcon className="h-5 w-5" />
            </button>
          </div>
        </div>

        <div className="bg-white shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Proposal #
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Customer
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Title
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {proposals.map((proposal) => (
                <tr key={proposal.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    #{proposal.proposal_number}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {proposal.customers?.name || 'N/A'}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-900">
                    {proposal.title}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {formatCurrency(proposal.total || 0)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {getStatusBadge(proposal.status)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {formatDate(proposal.created_at)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div className="flex items-center justify-end gap-2">
                      <Link
                        href={`/proposals/${proposal.id}`}
                        className="text-blue-600 hover:text-blue-900"
                        title="View"
                      >
                        <EyeIcon className="h-5 w-5" />
                      </Link>
                      {(proposal.status === 'draft' || proposal.status === 'sent') && (
                        <Link
                          href={`/proposals/${proposal.id}/edit`}
                          className="text-gray-600 hover:text-gray-900"
                          title="Edit"
                        >
                          <PencilIcon className="h-5 w-5" />
                        </Link>
                      )}
                      {proposal.status !== 'paid' && (
                        <SendProposal
                          proposalId={proposal.id}
                          proposalNumber={proposal.proposal_number}
                          customerEmail={proposal.customers?.email}
                          customerName={proposal.customers?.name}
                          variant="icon"
                        />
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    )
  }

  // Box view
  return (
    <div>
      <div className="flex justify-end mb-4">
        <div className="flex gap-2">
          <button
            onClick={() => setViewMode('box')}
            className="p-2 text-gray-900 bg-gray-100 rounded"
            title="Box View"
          >
            <Squares2X2Icon className="h-5 w-5" />
          </button>
          <button
            onClick={() => setViewMode('list')}
            className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded"
            title="List View"
          >
            <ListBulletIcon className="h-5 w-5" />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {proposals.map((proposal) => (
          <div key={proposal.id} className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow">
            <div className="p-6">
              <div className="flex justify-between items-start mb-4">
                <h3 className="text-lg font-semibold text-gray-900">
                  #{proposal.proposal_number}
                </h3>
                {getStatusBadge(proposal.status)}
              </div>
              
              <p className="text-gray-900 font-medium mb-2">{proposal.title}</p>
              <p className="text-sm text-gray-600 mb-1">
                Customer: {proposal.customers?.name || 'N/A'}
              </p>
              <p className="text-sm text-gray-600 mb-3">
                Date: {formatDate(proposal.created_at)}
              </p>
              
              <div className="border-t pt-3 mb-4">
                <p className="text-2xl font-bold text-green-600">
                  {formatCurrency(proposal.total || 0)}
                </p>
              </div>
              
              <div className="flex gap-2">
                <Link
                  href={`/proposals/${proposal.id}`}
                  className="flex-1 text-center px-3 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  View
                </Link>
                {(proposal.status === 'draft' || proposal.status === 'sent') && (
                  <Link
                    href={`/proposals/${proposal.id}/edit`}
                    className="flex-1 text-center px-3 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
                  >
                    Edit
                  </Link>
                )}
                {proposal.status !== 'paid' && (
                  <SendProposal
                    proposalId={proposal.id}
                    proposalNumber={proposal.proposal_number}
                    customerEmail={proposal.customers?.email}
                    customerName={proposal.customers?.name}
                    variant="button"
                    buttonText="Send"
                  />
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
