#!/bin/bash

echo "🔧 Replacing ProposalsList.tsx with fixed version..."

# Create the complete fixed file
cat > app/proposals/ProposalsList.tsx << 'EOF'
'use client'

import { useState } from 'react'
import * as React from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface ProposalData {
  id: string
  proposal_number: string
  title: string
  total: number
  status: string
  created_at: string
  updated_at: string
  customers: Customer[] // Array from Supabase
}

interface ProposalsListProps {
  proposals: ProposalData[]
  searchParams: {
    status?: string
    startDate?: string
    endDate?: string
    search?: string
  }
}

export default function ProposalsList({ proposals, searchParams }: ProposalsListProps) {
  const router = useRouter()
  const currentSearchParams = useSearchParams()
  
  // Filter states
  const [filters, setFilters] = useState({
    status: searchParams.status || 'all',
    startDate: searchParams.startDate || '',
    endDate: searchParams.endDate || '',
    search: searchParams.search || ''
  })

  // Sorting state
  const [sortConfig, setSortConfig] = useState<{
    key: keyof ProposalData | 'customer_name' | 'customer_email'
    direction: 'asc' | 'desc'
  } | null>(null)

  const [showFilters, setShowFilters] = useState(false)

  // Status options
  const statusOptions = [
    { value: 'all', label: 'All Statuses', color: 'bg-gray-100 text-gray-800' },
    { value: 'draft', label: 'Draft', color: 'bg-gray-100 text-gray-800' },
    { value: 'sent', label: 'Sent', color: 'bg-blue-100 text-blue-800' },
    { value: 'viewed', label: 'Viewed', color: 'bg-purple-100 text-purple-800' },
    { value: 'approved', label: 'Approved', color: 'bg-green-100 text-green-800' },
    { value: 'rejected', label: 'Rejected', color: 'bg-red-100 text-red-800' },
    { value: 'paid', label: 'Paid', color: 'bg-emerald-100 text-emerald-800' }
  ]

  // Sorting functionality
  const handleSort = (key: keyof ProposalData | 'customer_name' | 'customer_email') => {
    let direction: 'asc' | 'desc' = 'asc'
    
    if (sortConfig && sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc'
    }
    
    setSortConfig({ key, direction })
  }

  // Sort proposals
  const sortedProposals = React.useMemo(() => {
    if (!sortConfig) return proposals

    return [...proposals].sort((a, b) => {
      let aValue: any
      let bValue: any

      switch (sortConfig.key) {
        case 'customer_name':
          aValue = a.customers?.[0]?.name || ''
          bValue = b.customers?.[0]?.name || ''
          break
        case 'customer_email':
          aValue = a.customers?.[0]?.email || ''
          bValue = b.customers?.[0]?.email || ''
          break
        case 'created_at':
          aValue = new Date(a.created_at).getTime()
          bValue = new Date(b.created_at).getTime()
          break
        case 'total':
          aValue = a.total
          bValue = b.total
          break
        default:
          aValue = a[sortConfig.key as keyof ProposalData]
          bValue = b[sortConfig.key as keyof ProposalData]
      }

      if (typeof aValue === 'string' && typeof bValue === 'string') {
        aValue = aValue.toLowerCase()
        bValue = bValue.toLowerCase()
      }

      if (aValue < bValue) {
        return sortConfig.direction === 'asc' ? -1 : 1
      }
      if (aValue > bValue) {
        return sortConfig.direction === 'asc' ? 1 : -1
      }
      return 0
    })
  }, [proposals, sortConfig])

  // Format currency
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  // Format date
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  // Get status color
  const getStatusColor = (status: string) => {
    const statusOption = statusOptions.find(opt => opt.value === status)
    return statusOption?.color || 'bg-gray-100 text-gray-800'
  }

  // Sort icon
  const getSortIcon = (key: string) => {
    if (!sortConfig || sortConfig.key !== key) {
      return <span className="ml-1 text-gray-400">↕</span>
    }
    return sortConfig.direction === 'asc' 
      ? <span className="ml-1 text-gray-700">↑</span>
      : <span className="ml-1 text-gray-700">↓</span>
  }

  // Apply filters
  const handleFilterChange = (key: string, value: string) => {
    const newFilters = { ...filters, [key]: value }
    setFilters(newFilters)
    
    // Update URL params
    const params = new URLSearchParams()
    Object.entries(newFilters).forEach(([k, v]) => {
      if (v && v !== 'all') params.set(k, v)
    })
    
    router.push(`/proposals?${params.toString()}`)
  }

  return (
    <>
      {/* Header */}
      <div className="mb-8">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Proposals</h1>
            <p className="text-gray-600 mt-1">{proposals.length} proposals found</p>
          </div>
          <div className="flex gap-3">
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
              </svg>
              Filters
            </button>
            <Link
              href="/proposals/new"
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              New Proposal
            </Link>
          </div>
        </div>
      </div>

      {/* Table */}
      {proposals.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow-sm">
          <p className="text-gray-500 mb-4">
            {searchParams.search || searchParams.status !== 'all' 
              ? 'No proposals found matching your filters. Try adjusting your filters or create a new proposal.'
              : 'Get started by creating your first proposal.'
            }
          </p>
          <Link
            href="/proposals/new"
            className="inline-flex px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Create Proposal
          </Link>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 select-none"
                    onClick={() => handleSort('proposal_number')}
                  >
                    <div className="flex items-center">
                      Proposal
                      {getSortIcon('proposal_number')}
                    </div>
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 select-none"
                    onClick={() => handleSort('customer_name')}
                  >
                    <div className="flex items-center">
                      Customer
                      {getSortIcon('customer_name')}
                    </div>
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 select-none"
                    onClick={() => handleSort('total')}
                  >
                    <div className="flex items-center">
                      Amount
                      {getSortIcon('total')}
                    </div>
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 select-none"
                    onClick={() => handleSort('status')}
                  >
                    <div className="flex items-center">
                      Status
                      {getSortIcon('status')}
                    </div>
                  </th>
                  <th 
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 select-none"
                    onClick={() => handleSort('created_at')}
                  >
                    <div className="flex items-center">
                      Date
                      {getSortIcon('created_at')}
                    </div>
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {sortedProposals.map((proposal) => (
                  <tr key={proposal.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {proposal.proposal_number}
                        </div>
                        <div className="text-sm text-gray-500 truncate max-w-xs">
                          {proposal.title}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {proposal.customers?.[0]?.name || 'No customer'}
                        </div>
                        <div className="text-sm text-gray-500">
                          {proposal.customers?.[0]?.email || ''}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {formatCurrency(proposal.total)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(proposal.status)}`}>
                        {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(proposal.created_at)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex justify-end gap-2">
                        <Link
                          href={`/proposals/${proposal.id}`}
                          className="text-blue-600 hover:text-blue-900"
                        >
                          View
                        </Link>
                        <Link
                          href={`/proposals/${proposal.id}/edit`}
                          className="text-gray-600 hover:text-gray-900"
                        >
                          Edit
                        </Link>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </>
  )
}
EOF

echo "✅ Created fixed ProposalsList.tsx"

# Stage the file
git add app/proposals/ProposalsList.tsx

# Commit with message
git commit -m "fix: complete rewrite of ProposalsList with proper customer data handling

- Added optional chaining for customers array access (customers?.[0])
- Added fallback values for missing customer data
- Fixed sorting functions to handle optional customer data"

# Push to GitHub
git push origin main

echo "✅ Done! The customer display issue should be fixed now."