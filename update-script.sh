#!/bin/bash
echo "🔧 Fixing customer array type issue in ProposalsList..."

# Update ProposalsList to handle customer data properly
cat > app/proposals/ProposalsList.tsx << 'EOF'
'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { formatCurrency, formatDate } from '@/lib/utils'
import { useRouter } from 'next/navigation'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
}

interface Proposal {
  id: string
  proposal_number: string
  customers: Customer
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
          customers!inner (
            id,
            name,
            email,
            phone
          )
        `)
        .order('created_at', { ascending: false })

      if (error) throw error
      
      // Transform the data to ensure customers is a single object
      const transformedData = (data || []).map(proposal => ({
        ...proposal,
        customers: Array.isArray(proposal.customers) ? proposal.customers[0] : proposal.customers
      }))
      
      setProposals(transformedData)
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
    echo "❌ Error updating ProposalsList.tsx"
    exit 1
fi

# Commit and push
git add .
git commit -m "fix: handle customer array/object type issue

- Transform customer data to ensure it's always an object
- Handle both array and object responses from Supabase
- Fix TypeScript type errors in ProposalsList"

git push origin main

echo "✅ Customer type issue fixed!"
echo ""
echo "📝 The fix:"
echo "- Added data transformation to handle customer as array or object"
echo "- Maps through data and extracts first element if array"
echo "- Ensures TypeScript types match expected structure"