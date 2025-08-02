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
