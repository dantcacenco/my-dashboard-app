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
  customers: Customer // Single object, not array
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
          aValue = a.customers?.name || ''
          bValue = b.customers?.name || ''
          break
        case 'customer_email':
          aValue = a.customers?.email || ''
          bValue = b.customers?.email || ''
          break
        default:
          aValue = a[sortConfig.key as keyof ProposalData]
          bValue = b[sortConfig.key as keyof ProposalData]
      }

      if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1
      if (aValue > bValue) return sortConfig.direction === 'asc' ? 1 : -1
      return 0
    })
  }, [proposals, sortConfig])

  // Apply filters
  const handleFilterChange = () => {
    const params = new URLSearchParams()
    
    if (filters.status !== 'all') params.set('status', filters.status)
    if (filters.startDate) params.set('startDate', filters.startDate)
    if (filters.endDate) params.set('endDate', filters.endDate)
    if (filters.search) params.set('search', filters.search)
    
    router.push(`/proposals?${params.toString()}`)
  }

  // Reset filters
  const handleResetFilters = () => {
    setFilters({
      status: 'all',
      startDate: '',
      endDate: '',
      search: ''
    })
    router.push('/proposals')
  }

  // Quick date filters
  const setDateRange = (days: number) => {
    const end = new Date()
    const start = new Date()
    start.setDate(start.getDate() - days)
    
    setFilters({
      ...filters,
      startDate: start.toISOString().split('T')[0],
      endDate: end.toISOString().split('T')[0]
    })
  }

  // Format date
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  // Format currency
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  // Get status color
  const getStatusColor = (status: string) => {
    const option = statusOptions.find(opt => opt.value === status)
    return option ? option.color : 'bg-gray-100 text-gray-800'
  }

  // Sort icon
  const getSortIcon = (column: string) => {
    if (!sortConfig || sortConfig.key !== column) {
      return <span className="text-gray-400 ml-1">↕</span>
    }
    return sortConfig.direction === 'asc' 
      ? <span className="text-blue-600 ml-1">↑</span>
      : <span className="text-blue-600 ml-1">↓</span>
  }

  return (
    <>
      {/* Header */}
      <div className="mb-6 flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">Proposals</h1>
        <div className="flex gap-3">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
            </svg>
            Filters
            {(searchParams.status !== 'all' || searchParams.startDate || searchParams.endDate || searchParams.search) && (
              <span className="bg-blue-600 text-white text-xs px-2 py-0.5 rounded-full">Active</span>
            )}
          </button>
          <Link
            href="/proposals/new"
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            New Proposal
          </Link>
        </div>
      </div>

      {/* Filters */}
      {showFilters && (
        <div className="mb-6 bg-white p-6 rounded-lg shadow-sm">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
            {/* Search */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Search
              </label>
              <input
                type="text"
                placeholder="Search proposals..."
                value={filters.search}
                onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                onKeyDown={(e) => e.key === 'Enter' && handleFilterChange()}
                className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
            
            {/* Status */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Status
              </label>
              <select
                value={filters.status}
                onChange={(e) => setFilters({ ...filters, status: e.target.value })}
                className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                {statusOptions.map(option => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Start Date */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Start Date
              </label>
              <input
                type="date"
                value={filters.startDate}
                onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
                className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            {/* End Date */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                End Date
              </label>
              <input
                type="date"
                value={filters.endDate}
                onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
                className="w-full p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          {/* Quick Date Ranges */}
          <div className="mb-4">
            <span className="text-sm text-gray-600 mr-3">Quick filters:</span>
            <button onClick={() => setDateRange(7)} className="text-sm text-blue-600 hover:underline mr-3">Last 7 days</button>
            <button onClick={() => setDateRange(30)} className="text-sm text-blue-600 hover:underline mr-3">Last 30 days</button>
            <button onClick={() => setDateRange(90)} className="text-sm text-blue-600 hover:underline">Last 90 days</button>
          </div>

          {/* Filter Actions */}
          <div className="flex gap-3">
            <button
              onClick={handleFilterChange}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Apply Filters
            </button>
            <button
              onClick={handleResetFilters}
              className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
            >
              Reset
            </button>
          </div>
        </div>
      )}

      {/* Results Summary */}
      <div className="mb-4 text-sm text-gray-600">
        Showing {sortedProposals.length} proposal{sortedProposals.length !== 1 ? 's' : ''}
        {searchParams.search && ` matching "${searchParams.search}"`}
      </div>

      {/* Proposals Table */}
      {sortedProposals.length === 0 ? (
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
                        <div className="text-sm text-gray-500">
                          {proposal.title}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm text-gray-900">
                          {proposal.customers?.name || 'No customer'}
                        </div>
                        <div className="text-sm text-gray-500">
                          {proposal.customers?.email || ''}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {formatCurrency(proposal.total)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(proposal.status)}`}>
                        {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(proposal.created_at)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <Link
                        href={`/proposals/${proposal.id}`}
                        className="text-blue-600 hover:text-blue-900"
                      >
                        View
                      </Link>
                      {proposal.status === 'draft' && (
                        <>
                          <span className="text-gray-300 mx-2">|</span>
                          <Link
                            href={`/proposals/${proposal.id}/edit`}
                            className="text-blue-600 hover:text-blue-900"
                          >
                            Edit
                          </Link>
                        </>
                      )}
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
