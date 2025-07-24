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
          aValue = a.customers[0]?.name || ''
          bValue = b.customers[0]?.name || ''
          break
        case 'customer_email':
          aValue = a.customers[0]?.email || ''
          bValue = b.customers[0]?.email || ''
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

  // Apply filters
  const applyFilters = () => {
    const params = new URLSearchParams()
    
    if (filters.status !== 'all') params.set('status', filters.status)
    if (filters.startDate) params.set('startDate', filters.startDate)
    if (filters.endDate) params.set('endDate', filters.endDate)
    if (filters.search.trim()) params.set('search', filters.search.trim())

    router.push(`/proposals?${params.toString()}`)
  }

  // Clear all filters
  const clearFilters = () => {
    setFilters({
      status: 'all',
      startDate: '',
      endDate: '',
      search: ''
    })
    router.push('/proposals')
  }

  // Quick date ranges
  const setQuickDateRange = (range: string) => {
    const today = new Date()
    let startDate = ''
    
    switch (range) {
      case 'today':
        startDate = today.toISOString().split('T')[0]
        setFilters({ ...filters, startDate, endDate: startDate })
        break
      case 'week':
        const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000)
        startDate = weekAgo.toISOString().split('T')[0]
        setFilters({ ...filters, startDate, endDate: today.toISOString().split('T')[0] })
        break
      case 'month':
        const monthAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000)
        startDate = monthAgo.toISOString().split('T')[0]
        setFilters({ ...filters, startDate, endDate: today.toISOString().split('T')[0] })
        break
      case 'quarter':
        const quarterAgo = new Date(today.getTime() - 90 * 24 * 60 * 60 * 1000)
        startDate = quarterAgo.toISOString().split('T')[0]
        setFilters({ ...filters, startDate, endDate: today.toISOString().split('T')[0] })
        break
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const getStatusColor = (status: string) => {
    const statusOption = statusOptions.find(option => option.value === status)
    return statusOption?.color || 'bg-gray-100 text-gray-800'
  }

  // Count active filters
  const activeFiltersCount = Object.values(filters).filter(value => 
    value && value !== 'all' && value.toString().trim() !== ''
  ).length

  return (
    <>
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Proposals</h1>
          <p className="text-gray-600 mt-2">
            {proposals.length} proposal{proposals.length !== 1 ? 's' : ''} found
          </p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`px-4 py-2 border rounded-lg hover:bg-gray-50 flex items-center gap-2 ${
              activeFiltersCount > 0 ? 'border-blue-500 text-blue-600' : 'border-gray-300 text-gray-700'
            }`}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.207A1 1 0 013 6.5V4z" />
            </svg>
            Filters
            {activeFiltersCount > 0 && (
              <span className="bg-blue-600 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                {activeFiltersCount}
              </span>
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

      {/* Filters Panel */}
      {showFilters && (
        <div className="bg-white rounded-lg shadow-sm border p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
            
            {/* Search */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Search
              </label>
              <input
                type="text"
                value={filters.search}
                onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                placeholder="Proposal #, title, customer..."
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
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Quick Date Ranges
            </label>
            <div className="flex gap-2 flex-wrap">
              <button
                onClick={() => setQuickDateRange('today')}
                className="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50"
              >
                Today
              </button>
              <button
                onClick={() => setQuickDateRange('week')}
                className="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50"
              >
                Last 7 Days
              </button>
              <button
                onClick={() => setQuickDateRange('month')}
                className="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50"
              >
                Last 30 Days
              </button>
              <button
                onClick={() => setQuickDateRange('quarter')}
                className="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50"
              >
                Last 90 Days
              </button>
            </div>
          </div>

          {/* Filter Actions */}
          <div className="flex gap-3">
            <button
              onClick={applyFilters}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Apply Filters
            </button>
            <button
              onClick={clearFilters}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
            >
              Clear All
            </button>
          </div>
        </div>
      )}

      {/* Proposals List */}
      {proposals.length === 0 ? (
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <svg className="w-12 h-12 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No proposals found</h3>
          <p className="text-gray-600 mb-4">
            {activeFiltersCount > 0 
              ? 'Try adjusting your filters or create a new proposal.'
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
                          {proposal.customers[0]?.name}
                        </div>
                        <div className="text-sm text-gray-500">
                          {proposal.customers[0]?.email}
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