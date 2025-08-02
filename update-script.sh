#!/bin/bash
echo "🔧 Adding payment tracking features for boss side..."

# First, update ProposalsList to show payment status
cat > app/proposals/ProposalsList.tsx << 'EOF'
'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { formatCurrency, formatDate } from '@/lib/utils'
import { useRouter } from 'next/navigation'

interface Proposal {
  id: string
  proposal_number: string
  customers: {
    id: string
    name: string
    email: string
    phone: string
  }
  title: string
  total: number
  status: string
  created_at: string
  sent_at: string | null
  approved_at: string | null
  rejected_at: string | null
  payment_status: string | null
  deposit_paid_at: string | null
  progress_paid_at: string | null
  final_paid_at: string | null
  total_paid: number | null
}

const getStatusBadge = (proposal: Proposal) => {
  // Check payment status first if approved
  if (proposal.status === 'approved' && proposal.payment_status) {
    switch (proposal.payment_status) {
      case 'paid':
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">Final Paid</span>
      case 'roughin_paid':
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">Rough-In Paid</span>
      case 'deposit_paid':
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">Deposit Paid</span>
      default:
        return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">Approved</span>
    }
  }

  // Regular status badges
  switch (proposal.status) {
    case 'draft':
      return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">Draft</span>
    case 'sent':
      return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">Sent</span>
    case 'viewed':
      return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">Viewed</span>
    case 'approved':
      return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">Approved</span>
    case 'rejected':
      return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">Rejected</span>
    default:
      return <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">{proposal.status}</span>
  }
}

const getPaymentProgress = (proposal: Proposal) => {
  if (proposal.status !== 'approved' || !proposal.total) return null

  const totalPaid = proposal.total_paid || 0
  const percentage = (totalPaid / proposal.total) * 100

  return (
    <div className="mt-2">
      <div className="flex justify-between text-xs text-gray-600 mb-1">
        <span>Payment Progress</span>
        <span>{percentage.toFixed(0)}%</span>
      </div>
      <div className="w-full bg-gray-200 rounded-full h-2">
        <div 
          className="bg-green-600 h-2 rounded-full transition-all duration-300"
          style={{ width: `${percentage}%` }}
        />
      </div>
      <div className="flex justify-between text-xs text-gray-500 mt-1">
        <span>Paid: {formatCurrency(totalPaid)}</span>
        <span>Total: {formatCurrency(proposal.total)}</span>
      </div>
    </div>
  )
}

export default function ProposalsList() {
  const [proposals, setProposals] = useState<Proposal[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<'all' | 'draft' | 'sent' | 'approved' | 'paid'>('all')
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    fetchProposals()
  }, [])

  const fetchProposals = async () => {
    try {
      const { data, error } = await supabase
        .from('proposals')
        .select(`
          id,
          proposal_number,
          title,
          total,
          status,
          created_at,
          sent_at,
          approved_at,
          rejected_at,
          payment_status,
          deposit_paid_at,
          progress_paid_at,
          final_paid_at,
          total_paid,
          customers (
            id,
            name,
            email,
            phone
          )
        `)
        .order('created_at', { ascending: false })

      if (error) throw error
      setProposals(data || [])
    } catch (error) {
      console.error('Error fetching proposals:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id: string, e: React.MouseEvent) => {
    e.preventDefault()
    if (!confirm('Are you sure you want to delete this proposal?')) return

    try {
      const { error } = await supabase
        .from('proposals')
        .delete()
        .eq('id', id)

      if (error) throw error
      fetchProposals()
    } catch (error) {
      console.error('Error deleting proposal:', error)
      alert('Failed to delete proposal')
    }
  }

  const filteredProposals = proposals.filter(proposal => {
    if (filter === 'all') return true
    if (filter === 'paid') return proposal.payment_status === 'paid' || proposal.payment_status === 'deposit_paid' || proposal.payment_status === 'roughin_paid'
    return proposal.status === filter
  })

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
      </div>
    )
  }

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <h1 className="text-2xl font-semibold text-gray-900">Proposals</h1>
        <Link
          href="/proposals/new"
          className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          Create Proposal
        </Link>
      </div>

      {/* Filter Tabs */}
      <div className="mb-6 border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {[
            { value: 'all', label: 'All' },
            { value: 'draft', label: 'Drafts' },
            { value: 'sent', label: 'Sent' },
            { value: 'approved', label: 'Approved' },
            { value: 'paid', label: 'With Payments' },
          ].map(({ value, label }) => (
            <button
              key={value}
              onClick={() => setFilter(value as any)}
              className={`${
                filter === value
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              } whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm`}
            >
              {label}
              <span className="ml-2 text-gray-400">
                ({proposals.filter(p => {
                  if (value === 'all') return true
                  if (value === 'paid') return p.payment_status === 'paid' || p.payment_status === 'deposit_paid' || p.payment_status === 'roughin_paid'
                  return p.status === value
                }).length})
              </span>
            </button>
          ))}
        </nav>
      </div>

      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        {filteredProposals.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500">No proposals found</p>
          </div>
        ) : (
          <ul className="divide-y divide-gray-200">
            {filteredProposals.map((proposal) => (
              <li key={proposal.id}>
                <Link href={`/proposals/${proposal.id}`} className="block hover:bg-gray-50">
                  <div className="px-4 py-4 sm:px-6">
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center justify-between">
                          <p className="text-sm font-medium text-blue-600 truncate">
                            {proposal.proposal_number}
                          </p>
                          <div className="ml-2 flex-shrink-0 flex">
                            {getStatusBadge(proposal)}
                          </div>
                        </div>
                        <div className="mt-2 sm:flex sm:justify-between">
                          <div className="sm:flex">
                            <p className="flex items-center text-sm text-gray-500">
                              {proposal.customers.name}
                            </p>
                            <p className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0 sm:ml-6">
                              {proposal.title}
                            </p>
                          </div>
                          <div className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                            <p className="font-semibold text-gray-900">
                              {formatCurrency(proposal.total)}
                            </p>
                          </div>
                        </div>
                        {/* Payment Progress Bar */}
                        {getPaymentProgress(proposal)}
                      </div>
                    </div>
                    <div className="mt-2 flex justify-between">
                      <p className="text-sm text-gray-500">
                        Created {formatDate(proposal.created_at)}
                      </p>
                      <div className="flex space-x-2">
                        <button
                          onClick={(e) => {
                            e.preventDefault()
                            router.push(`/proposals/${proposal.id}/edit`)
                          }}
                          className="text-sm text-blue-600 hover:text-blue-900"
                        >
                          Edit
                        </button>
                        <button
                          onClick={(e) => handleDelete(proposal.id, e)}
                          className="text-sm text-red-600 hover:text-red-900"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error updating ProposalsList"
    exit 1
fi

# Update ProposalView to show payment progress
cat > app/proposals/\[id\]/ProposalView.tsx << 'EOF'
'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { formatCurrency, formatDate } from '@/lib/utils'
import SendProposal from './SendProposal'

interface ProposalItem {
  id: string
  name: string
  description: string
  quantity: number
  unit_price: number
  total_price: number
  is_addon: boolean
}

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface Proposal {
  id: string
  proposal_number: string
  customer_id: string
  title: string
  description: string
  subtotal: number
  tax_rate: number
  tax_amount: number
  total: number
  status: string
  valid_until: string | null
  signed_at: string | null
  signature_data: string | null
  created_at: string
  sent_at: string | null
  approved_at: string | null
  rejected_at: string | null
  customer_notes: string | null
  customer_view_token: string
  payment_status: string | null
  deposit_paid_at: string | null
  deposit_amount: number | null
  progress_paid_at: string | null
  progress_payment_amount: number | null
  final_paid_at: string | null
  final_payment_amount: number | null
  total_paid: number | null
  customers: Customer
  proposal_items: ProposalItem[]
}

export default function ProposalView({ proposalId }: { proposalId: string }) {
  const [proposal, setProposal] = useState<Proposal | null>(null)
  const [loading, setLoading] = useState(true)
  const [showSendModal, setShowSendModal] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    fetchProposal()
  }, [proposalId])

  const fetchProposal = async () => {
    try {
      const { data, error } = await supabase
        .from('proposals')
        .select(`
          *,
          customers (
            id,
            name,
            email,
            phone,
            address
          ),
          proposal_items (
            id,
            name,
            description,
            quantity,
            unit_price,
            total_price,
            is_addon
          )
        `)
        .eq('id', proposalId)
        .single()

      if (error) throw error
      setProposal(data)
    } catch (error) {
      console.error('Error fetching proposal:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this proposal?')) return

    try {
      const { error } = await supabase
        .from('proposals')
        .delete()
        .eq('id', proposalId)

      if (error) throw error
      router.push('/proposals')
    } catch (error) {
      console.error('Error deleting proposal:', error)
      alert('Failed to delete proposal')
    }
  }

  const getStatusBadge = () => {
    if (!proposal) return null

    // Check payment status first if approved
    if (proposal.status === 'approved' && proposal.payment_status) {
      switch (proposal.payment_status) {
        case 'paid':
          return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">Final Payment Complete</span>
        case 'roughin_paid':
          return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">Rough-In Payment Received</span>
        case 'deposit_paid':
          return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-indigo-100 text-indigo-800">Deposit Payment Received</span>
        default:
          return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800">Approved - Awaiting Payment</span>
      }
    }

    switch (proposal.status) {
      case 'draft':
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800">Draft</span>
      case 'sent':
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">Sent</span>
      case 'viewed':
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-purple-100 text-purple-800">Viewed by Customer</span>
      case 'approved':
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800">Approved</span>
      case 'rejected':
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800">Rejected</span>
      default:
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800">{proposal.status}</span>
    }
  }

  const getPaymentProgress = () => {
    if (!proposal || proposal.status !== 'approved' || !proposal.total) return null

    const depositAmount = proposal.total * 0.5
    const roughInAmount = proposal.total * 0.3
    const finalAmount = proposal.total * 0.2
    const totalPaid = proposal.total_paid || 0
    const percentage = (totalPaid / proposal.total) * 100

    return (
      <div className="bg-white shadow sm:rounded-lg p-6 mb-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Payment Progress</h3>
        
        {/* Progress Bar */}
        <div className="mb-6">
          <div className="flex justify-between text-sm text-gray-600 mb-2">
            <span>Overall Progress</span>
            <span>{percentage.toFixed(0)}% Complete</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div 
              className="bg-green-600 h-3 rounded-full transition-all duration-300"
              style={{ width: `${percentage}%` }}
            />
          </div>
          <div className="flex justify-between text-sm text-gray-600 mt-2">
            <span>Paid: {formatCurrency(totalPaid)}</span>
            <span>Remaining: {formatCurrency(proposal.total - totalPaid)}</span>
          </div>
        </div>

        {/* Payment Stages */}
        <div className="grid grid-cols-3 gap-4">
          <div className={`border rounded-lg p-4 ${proposal.deposit_paid_at ? 'border-green-500 bg-green-50' : 'border-gray-300'}`}>
            <h4 className="font-medium text-gray-900">50% Deposit</h4>
            <p className="text-xl font-bold mt-1">{formatCurrency(depositAmount)}</p>
            <p className="text-sm text-gray-600 mt-2">
              {proposal.deposit_paid_at ? (
                <span className="text-green-600">✓ Paid on {formatDate(proposal.deposit_paid_at)}</span>
              ) : (
                <span className="text-gray-500">Pending</span>
              )}
            </p>
          </div>

          <div className={`border rounded-lg p-4 ${proposal.progress_paid_at ? 'border-green-500 bg-green-50' : 'border-gray-300'}`}>
            <h4 className="font-medium text-gray-900">30% Rough-In</h4>
            <p className="text-xl font-bold mt-1">{formatCurrency(roughInAmount)}</p>
            <p className="text-sm text-gray-600 mt-2">
              {proposal.progress_paid_at ? (
                <span className="text-green-600">✓ Paid on {formatDate(proposal.progress_paid_at)}</span>
              ) : (
                <span className="text-gray-500">Pending</span>
              )}
            </p>
          </div>

          <div className={`border rounded-lg p-4 ${proposal.final_paid_at ? 'border-green-500 bg-green-50' : 'border-gray-300'}`}>
            <h4 className="font-medium text-gray-900">20% Final</h4>
            <p className="text-xl font-bold mt-1">{formatCurrency(finalAmount)}</p>
            <p className="text-sm text-gray-600 mt-2">
              {proposal.final_paid_at ? (
                <span className="text-green-600">✓ Paid on {formatDate(proposal.final_paid_at)}</span>
              ) : (
                <span className="text-gray-500">Pending</span>
              )}
            </p>
          </div>
        </div>

        <div className="mt-4 text-sm text-gray-600">
          <p>To manually update payment status, use the Edit button above.</p>
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
      </div>
    )
  }

  if (!proposal) {
    return <div>Proposal not found</div>
  }

  return (
    <div>
      <div className="mb-6 flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">
            Proposal #{proposal.proposal_number}
          </h1>
          <div className="mt-2">{getStatusBadge()}</div>
        </div>
        <div className="flex space-x-3">
          <button
            onClick={() => setShowSendModal(true)}
            className="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
          >
            Send to Customer
          </button>
          <Link
            href={`/proposals/${proposalId}/edit`}
            className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Edit
          </Link>
          <button
            onClick={handleDelete}
            className="bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
          >
            Delete
          </button>
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
            <div className="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt className="text-sm font-medium text-gray-500">Total Amount</dt>
              <dd className="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <p className="text-xl font-bold">{formatCurrency(proposal.total)}</p>
                <p className="text-gray-500">Subtotal: {formatCurrency(proposal.subtotal)}</p>
                <p className="text-gray-500">Tax ({(proposal.tax_rate * 100).toFixed(2)}%): {formatCurrency(proposal.tax_amount)}</p>
              </dd>
            </div>
          </dl>
        </div>
      </div>

      {/* Line Items */}
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
                  Type
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
              {proposal.proposal_items.map((item) => (
                <tr key={item.id}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    <p className="font-medium">{item.name}</p>
                    {item.description && (
                      <p className="text-gray-500">{item.description}</p>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {item.is_addon ? 'Add-on' : 'Service'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {item.quantity}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {formatCurrency(item.unit_price)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-medium">
                    {formatCurrency(item.total_price)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showSendModal && (
        <SendProposal
          proposal={proposal}
          onClose={() => setShowSendModal(false)}
          onSent={() => {
            setShowSendModal(false)
            fetchProposal()
          }}
        />
      )}
    </div>
  )
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error updating ProposalView"
    exit 1
fi

# Now add payment editing to the edit proposal page
echo "🔧 Adding payment editing section to edit proposal page..."

# We need to update the edit page to include payment controls
# First, let's check if we need to create a payment editing component
cat > app/proposals/\[id\]/edit/PaymentEditSection.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { formatCurrency } from '@/lib/utils'

interface PaymentEditSectionProps {
  proposal: any
  onUpdate: (updates: any) => void
}

export default function PaymentEditSection({ proposal, onUpdate }: PaymentEditSectionProps) {
  const [paymentData, setPaymentData] = useState({
    deposit_paid: !!proposal.deposit_paid_at,
    deposit_amount: proposal.deposit_amount || proposal.total * 0.5,
    roughin_paid: !!proposal.progress_paid_at,
    roughin_amount: proposal.progress_payment_amount || proposal.total * 0.3,
    final_paid: !!proposal.final_paid_at,
    final_amount: proposal.final_payment_amount || proposal.total * 0.2,
    payment_method: proposal.payment_method || 'card'
  })

  const handlePaymentToggle = (stage: 'deposit' | 'roughin' | 'final') => {
    const updates: any = {}
    const now = new Date().toISOString()

    switch (stage) {
      case 'deposit':
        if (!paymentData.deposit_paid) {
          updates.deposit_paid_at = now
          updates.deposit_amount = paymentData.deposit_amount
          updates.payment_status = 'deposit_paid'
        } else {
          updates.deposit_paid_at = null
          updates.deposit_amount = null
          updates.payment_status = 'pending'
        }
        setPaymentData({ ...paymentData, deposit_paid: !paymentData.deposit_paid })
        break

      case 'roughin':
        if (!paymentData.roughin_paid) {
          updates.progress_paid_at = now
          updates.progress_payment_amount = paymentData.roughin_amount
          updates.payment_status = 'roughin_paid'
        } else {
          updates.progress_paid_at = null
          updates.progress_payment_amount = null
          updates.payment_status = paymentData.deposit_paid ? 'deposit_paid' : 'pending'
        }
        setPaymentData({ ...paymentData, roughin_paid: !paymentData.roughin_paid })
        break

      case 'final':
        if (!paymentData.final_paid) {
          updates.final_paid_at = now
          updates.final_payment_amount = paymentData.final_amount
          updates.payment_status = 'paid'
        } else {
          updates.final_paid_at = null
          updates.final_payment_amount = null
          updates.payment_status = paymentData.roughin_paid ? 'roughin_paid' : 
                                 paymentData.deposit_paid ? 'deposit_paid' : 'pending'
        }
        setPaymentData({ ...paymentData, final_paid: !paymentData.final_paid })
        break
    }

    // Calculate total paid
    let totalPaid = 0
    if (stage === 'deposit' ? !paymentData.deposit_paid : paymentData.deposit_paid) {
      totalPaid += paymentData.deposit_amount
    }
    if (stage === 'roughin' ? !paymentData.roughin_paid : paymentData.roughin_paid) {
      totalPaid += paymentData.roughin_amount
    }
    if (stage === 'final' ? !paymentData.final_paid : paymentData.final_paid) {
      totalPaid += paymentData.final_amount
    }
    updates.total_paid = totalPaid

    onUpdate(updates)
  }

  const handleAmountChange = (stage: 'deposit' | 'roughin' | 'final', value: string) => {
    const amount = parseFloat(value) || 0
    const updates: any = {}

    switch (stage) {
      case 'deposit':
        setPaymentData({ ...paymentData, deposit_amount: amount })
        if (paymentData.deposit_paid) {
          updates.deposit_amount = amount
        }
        break
      case 'roughin':
        setPaymentData({ ...paymentData, roughin_amount: amount })
        if (paymentData.roughin_paid) {
          updates.progress_payment_amount = amount
        }
        break
      case 'final':
        setPaymentData({ ...paymentData, final_amount: amount })
        if (paymentData.final_paid) {
          updates.final_payment_amount = amount
        }
        break
    }

    if (Object.keys(updates).length > 0) {
      // Recalculate total paid
      let totalPaid = 0
      if (paymentData.deposit_paid) {
        totalPaid += stage === 'deposit' ? amount : paymentData.deposit_amount
      }
      if (paymentData.roughin_paid) {
        totalPaid += stage === 'roughin' ? amount : paymentData.roughin_amount
      }
      if (paymentData.final_paid) {
        totalPaid += stage === 'final' ? amount : paymentData.final_amount
      }
      updates.total_paid = totalPaid
      onUpdate(updates)
    }
  }

  if (proposal.status !== 'approved') {
    return (
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <p className="text-yellow-800">Payment tracking is only available for approved proposals.</p>
      </div>
    )
  }

  const totalPaid = (paymentData.deposit_paid ? paymentData.deposit_amount : 0) +
                   (paymentData.roughin_paid ? paymentData.roughin_amount : 0) +
                   (paymentData.final_paid ? paymentData.final_amount : 0)
  const percentage = proposal.total > 0 ? (totalPaid / proposal.total) * 100 : 0

  return (
    <div className="space-y-6">
      <div className="bg-white shadow sm:rounded-lg p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Payment Management</h3>
        
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <p className="text-sm text-blue-800">
            Use this section to manually track payments received outside of Stripe (cash, check, etc.) 
            or to correct payment records if needed.
          </p>
        </div>

        {/* Progress Overview */}
        <div className="mb-6">
          <div className="flex justify-between text-sm text-gray-600 mb-2">
            <span>Overall Payment Progress</span>
            <span>{percentage.toFixed(0)}% Complete</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-3">
            <div 
              className="bg-green-600 h-3 rounded-full transition-all duration-300"
              style={{ width: `${percentage}%` }}
            />
          </div>
          <div className="flex justify-between text-sm text-gray-600 mt-2">
            <span>Total Paid: {formatCurrency(totalPaid)}</span>
            <span>Total Due: {formatCurrency(proposal.total)}</span>
          </div>
        </div>

        {/* Payment Method */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Payment Method
          </label>
          <select
            value={paymentData.payment_method}
            onChange={(e) => {
              setPaymentData({ ...paymentData, payment_method: e.target.value })
              onUpdate({ payment_method: e.target.value })
            }}
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
          >
            <option value="card">Credit Card</option>
            <option value="ach">ACH/Bank Transfer</option>
            <option value="cash">Cash</option>
            <option value="check">Check</option>
            <option value="other">Other</option>
          </select>
        </div>

        {/* Payment Stages */}
        <div className="space-y-4">
          {/* Deposit */}
          <div className="border rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="deposit-paid"
                  checked={paymentData.deposit_paid}
                  onChange={() => handlePaymentToggle('deposit')}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="deposit-paid" className="ml-2 text-sm font-medium text-gray-900">
                  50% Deposit Paid
                </label>
              </div>
              <input
                type="number"
                value={paymentData.deposit_amount}
                onChange={(e) => handleAmountChange('deposit', e.target.value)}
                className="ml-4 w-32 px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                step="0.01"
              />
            </div>
            {proposal.deposit_paid_at && (
              <p className="text-xs text-gray-500 ml-6">
                Originally paid on: {new Date(proposal.deposit_paid_at).toLocaleDateString()}
              </p>
            )}
          </div>

          {/* Rough-In */}
          <div className="border rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="roughin-paid"
                  checked={paymentData.roughin_paid}
                  onChange={() => handlePaymentToggle('roughin')}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="roughin-paid" className="ml-2 text-sm font-medium text-gray-900">
                  30% Rough-In Paid
                </label>
              </div>
              <input
                type="number"
                value={paymentData.roughin_amount}
                onChange={(e) => handleAmountChange('roughin', e.target.value)}
                className="ml-4 w-32 px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                step="0.01"
              />
            </div>
            {proposal.progress_paid_at && (
              <p className="text-xs text-gray-500 ml-6">
                Originally paid on: {new Date(proposal.progress_paid_at).toLocaleDateString()}
              </p>
            )}
          </div>

          {/* Final */}
          <div className="border rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="final-paid"
                  checked={paymentData.final_paid}
                  onChange={() => handlePaymentToggle('final')}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="final-paid" className="ml-2 text-sm font-medium text-gray-900">
                  20% Final Paid
                </label>
              </div>
              <input
                type="number"
                value={paymentData.final_amount}
                onChange={(e) => handleAmountChange('final', e.target.value)}
                className="ml-4 w-32 px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                step="0.01"
              />
            </div>
            {proposal.final_paid_at && (
              <p className="text-xs text-gray-500 ml-6">
                Originally paid on: {new Date(proposal.final_paid_at).toLocaleDateString()}
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error creating PaymentEditSection"
    exit 1
fi

# Commit and push
git add .
git commit -m "feat: add payment tracking features for boss side

- Update ProposalsList to show payment status badges
- Add payment progress bars to proposals list
- Show detailed payment tracking in ProposalView
- Create PaymentEditSection component for manual payment updates
- Allow boss to toggle payment status and adjust amounts
- Show payment timeline and method selection
- Display deposit/rough-in/final payment status clearly"

git push origin main

echo "✅ Payment tracking features added successfully!"
echo ""
echo "📝 Features implemented:"
echo "1. Proposals list now shows:"
echo "   - Payment status badges (Deposit Paid, Rough-In Paid, Final Paid)"
echo "   - Payment progress bars with percentages"
echo "   - Filter for proposals with payments"
echo ""
echo "2. Proposal view shows:"
echo "   - Detailed payment progress section"
echo "   - Status for each payment stage"
echo "   - Visual indicators for completed payments"
echo ""
echo "3. Edit proposal will include:"
echo "   - PaymentEditSection component"
echo "   - Toggle payments on/off"
echo "   - Adjust payment amounts"
echo "   - Track payment methods (cash, check, etc.)"
echo ""
echo "⚠️ Note: You'll need to import and use PaymentEditSection in your edit page"