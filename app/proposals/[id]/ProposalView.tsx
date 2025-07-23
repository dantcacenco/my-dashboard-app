'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import SendProposal from './SendProposal'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface ProposalItem {
  id: string
  pricing_item_id: string
  name: string
  description: string
  quantity: number
  unit_price: number
  total_price: number
  is_addon: boolean
  is_selected: boolean
  sort_order: number
}

interface ProposalData {
  id: string
  proposal_number: string
  title: string
  description: string
  subtotal: number
  tax_rate: number
  tax_amount: number
  total: number
  status: string
  created_at: string
  updated_at: string
  customers: Customer
  proposal_items: ProposalItem[]
}

interface ProposalViewProps {
  proposal: ProposalData
  userRole: string
}

export default function ProposalView({ proposal, userRole }: ProposalViewProps) {
  const [showPrintView, setShowPrintView] = useState(false)
  const [showSendModal, setShowSendModal] = useState(false)
  const router = useRouter()

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
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
    switch (status) {
      case 'draft':
        return 'bg-gray-100 text-gray-800'
      case 'sent':
        return 'bg-blue-100 text-blue-800'
      case 'viewed':
        return 'bg-yellow-100 text-yellow-800'
      case 'approved':
        return 'bg-green-100 text-green-800'
      case 'rejected':
        return 'bg-red-100 text-red-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  // Separate selected items and add-ons
  const selectedItems = proposal.proposal_items
    .filter(item => !item.is_addon && item.is_selected)
    .sort((a, b) => a.sort_order - b.sort_order)
  
  const selectedAddons = proposal.proposal_items
    .filter(item => item.is_addon && item.is_selected)
    .sort((a, b) => a.sort_order - b.sort_order)

  const handlePrint = () => {
    window.print()
  }

  if (showPrintView) {
    return (
      <div className="max-w-4xl mx-auto bg-white p-8 print:p-0 print:shadow-none">
        {/* Print Header */}
        <div className="flex justify-between items-start mb-8 print:mb-6">
          <div>
            <h1 className="text-3xl font-bold text-blue-600 print:text-black">Service Pro</h1>
            <p className="text-gray-600 print:text-gray-800">Professional HVAC Services</p>
            <div className="mt-2 text-sm text-gray-600 print:text-gray-800">
              <p>Email: info@servicepro.com</p>
              <p>Phone: (555) 123-4567</p>
            </div>
          </div>
          <div className="text-right">
            <h2 className="text-2xl font-bold print:text-black">PROPOSAL</h2>
            <p className="text-lg font-semibold text-blue-600 print:text-black">{proposal.proposal_number}</p>
            <p className="text-sm text-gray-600 print:text-gray-800">{formatDate(proposal.created_at)}</p>
          </div>
        </div>

        {/* Customer Information */}
        <div className="grid grid-cols-2 gap-8 mb-8 print:mb-6">
          <div>
            <h3 className="font-semibold text-gray-900 mb-2">Proposal For:</h3>
            <div className="text-gray-700">
              <p className="font-medium">{proposal.customers.name}</p>
              <p>{proposal.customers.email}</p>
              <p>{proposal.customers.phone}</p>
              {proposal.customers.address && (
                <p className="mt-1">{proposal.customers.address}</p>
              )}
            </div>
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 mb-2">Proposal Details:</h3>
            <div className="text-gray-700">
              <p><span className="font-medium">Title:</span> {proposal.title}</p>
              <p><span className="font-medium">Status:</span> {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}</p>
              {proposal.description && (
                <p className="mt-2"><span className="font-medium">Description:</span></p>
              )}
            </div>
            {proposal.description && (
              <p className="text-gray-600 text-sm mt-1">{proposal.description}</p>
            )}
          </div>
        </div>

        {/* Services Table */}
        <div className="mb-6">
          <h3 className="text-lg font-semibold mb-4">Services & Materials</h3>
          <table className="w-full border-collapse border border-gray-300">
            <thead>
              <tr className="bg-gray-50 print:bg-gray-100">
                <th className="border border-gray-300 px-4 py-2 text-left">Description</th>
                <th className="border border-gray-300 px-4 py-2 text-center">Qty</th>
                <th className="border border-gray-300 px-4 py-2 text-right">Unit Price</th>
                <th className="border border-gray-300 px-4 py-2 text-right">Total</th>
              </tr>
            </thead>
            <tbody>
              {selectedItems.map((item) => (
                <tr key={item.id}>
                  <td className="border border-gray-300 px-4 py-2">
                    <div className="font-medium">{item.name}</div>
                    <div className="text-sm text-gray-600">{item.description}</div>
                  </td>
                  <td className="border border-gray-300 px-4 py-2 text-center">{item.quantity}</td>
                  <td className="border border-gray-300 px-4 py-2 text-right">{formatCurrency(item.unit_price)}</td>
                  <td className="border border-gray-300 px-4 py-2 text-right font-medium">{formatCurrency(item.total_price)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Add-ons Table */}
        {selectedAddons.length > 0 && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-4">Optional Add-ons (Selected)</h3>
            <table className="w-full border-collapse border border-gray-300">
              <thead>
                <tr className="bg-orange-50 print:bg-gray-100">
                  <th className="border border-gray-300 px-4 py-2 text-left">Description</th>
                  <th className="border border-gray-300 px-4 py-2 text-center">Qty</th>
                  <th className="border border-gray-300 px-4 py-2 text-right">Unit Price</th>
                  <th className="border border-gray-300 px-4 py-2 text-right">Total</th>
                </tr>
              </thead>
              <tbody>
                {selectedAddons.map((item) => (
                  <tr key={item.id}>
                    <td className="border border-gray-300 px-4 py-2">
                      <div className="font-medium">{item.name}</div>
                      <div className="text-sm text-gray-600">{item.description}</div>
                    </td>
                    <td className="border border-gray-300 px-4 py-2 text-center">{item.quantity}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right">{formatCurrency(item.unit_price)}</td>
                    <td className="border border-gray-300 px-4 py-2 text-right font-medium">{formatCurrency(item.total_price)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Totals */}
        <div className="flex justify-end mb-8 print:mb-6">
          <div className="w-64">
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Subtotal:</span>
                <span>{formatCurrency(proposal.subtotal)}</span>
              </div>
              <div className="flex justify-between">
                <span>Tax ({(proposal.tax_rate * 100).toFixed(1)}%):</span>
                <span>{formatCurrency(proposal.tax_amount)}</span>
              </div>
              <div className="border-t pt-2 flex justify-between font-bold text-lg">
                <span>Total:</span>
                <span>{formatCurrency(proposal.total)}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="border-t pt-6 print:pt-4 text-sm text-gray-600 print:text-gray-800">
          <p className="font-medium mb-2">Terms & Conditions:</p>
          <ul className="space-y-1 text-xs">
            <li>• This proposal is valid for 30 days from the date above</li>
            <li>• Work will begin upon signed approval and initial payment</li>
            <li>• All materials and workmanship are guaranteed for 1 year</li>
            <li>• Payment terms: 50% deposit, 30% at substantial completion, 20% final payment</li>
          </ul>
          <div className="mt-4 text-center">
            <p className="font-medium">Thank you for choosing Service Pro!</p>
          </div>
        </div>

        {/* Print buttons */}
        <div className="print:hidden mt-8 flex gap-4 justify-center">
          <button
            onClick={handlePrint}
            className="px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Print Proposal
          </button>
          <button
            onClick={() => setShowPrintView(false)}
            className="px-6 py-2 border border-gray-300 text-gray-700 rounded hover:bg-gray-50"
          >
            Back to View
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <Link
                href="/proposals"
                className="text-blue-600 hover:text-blue-800 flex items-center"
              >
                <svg className="w-5 h-5 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
                Back to Proposals
              </Link>
              <div>
                <h1 className="text-3xl font-bold text-gray-900">{proposal.proposal_number}</h1>
                <p className="text-gray-600">{proposal.title}</p>
              </div>
            </div>
            <div className="flex items-center space-x-3">
              <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(proposal.status)}`}>
                {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
              </span>
              {userRole === 'boss' && (
                <Link
                  href={`/proposals/${proposal.id}/edit`}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Edit Proposal
                </Link>
              )}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Customer Information */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-semibold mb-4">Customer Information</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h3 className="font-medium text-gray-900">{proposal.customers.name}</h3>
                  <p className="text-gray-600">{proposal.customers.email}</p>
                  <p className="text-gray-600">{proposal.customers.phone}</p>
                </div>
                <div>
                  {proposal.customers.address && (
                    <div>
                      <h4 className="font-medium text-gray-900 mb-1">Address:</h4>
                      <p className="text-gray-600">{proposal.customers.address}</p>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Proposal Details */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-semibold mb-4">Proposal Details</h2>
              {proposal.description && (
                <div className="mb-4">
                  <h3 className="font-medium text-gray-900 mb-2">Description:</h3>
                  <p className="text-gray-600">{proposal.description}</p>
                </div>
              )}
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="font-medium">Created:</span> {formatDate(proposal.created_at)}
                </div>
                <div>
                  <span className="font-medium">Last Updated:</span> {formatDate(proposal.updated_at)}
                </div>
              </div>
            </div>

            {/* Services & Materials */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-semibold mb-4">Services & Materials</h2>
              <div className="space-y-4">
                {selectedItems.map((item) => (
                  <div key={item.id} className="border rounded-lg p-4">
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <h4 className="font-medium">{item.name}</h4>
                        <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                        <div className="flex items-center gap-4 mt-2 text-sm">
                          <span>Qty: {item.quantity}</span>
                          <span>@ {formatCurrency(item.unit_price)}</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <span className="font-bold text-green-600">{formatCurrency(item.total_price)}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Add-ons */}
              {selectedAddons.length > 0 && (
                <div className="mt-6">
                  <h3 className="font-medium text-gray-900 mb-3">Selected Add-ons</h3>
                  <div className="space-y-3">
                    {selectedAddons.map((item) => (
                      <div key={item.id} className="border rounded-lg p-3 bg-orange-50 border-orange-200">
                        <div className="flex justify-between items-start">
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <h4 className="font-medium">{item.name}</h4>
                              <span className="text-xs bg-orange-200 px-2 py-1 rounded">Add-on</span>
                            </div>
                            <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                            <div className="flex items-center gap-4 mt-2 text-sm">
                              <span>Qty: {item.quantity}</span>
                              <span>@ {formatCurrency(item.unit_price)}</span>
                            </div>
                          </div>
                          <div className="text-right">
                            <span className="font-bold text-green-600">{formatCurrency(item.total_price)}</span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Proposal Summary */}
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-4">Proposal Summary</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span>Subtotal:</span>
                  <span>{formatCurrency(proposal.subtotal)}</span>
                </div>
                <div className="flex justify-between">
                  <span>Tax ({(proposal.tax_rate * 100).toFixed(1)}%):</span>
                  <span>{formatCurrency(proposal.tax_amount)}</span>
                </div>
                <div className="border-t pt-2 flex justify-between font-bold text-lg">
                  <span>Total:</span>
                  <span className="text-green-600">{formatCurrency(proposal.total)}</span>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-4">Actions</h3>
              <div className="space-y-3">
                <button
                  onClick={() => setShowPrintView(true)}
                  className="w-full px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Print/PDF View
                </button>
                {userRole === 'boss' && (
                  <>
                    <Link
                      href={`/proposals/${proposal.id}/edit`}
                      className="block w-full px-4 py-2 border border-gray-300 text-gray-700 rounded hover:bg-gray-50 text-center"
                    >
                      Edit Proposal
                    </Link>
                    <button
                      onClick={() => setShowSendModal(true)}
                      className="w-full px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
                    >
                      Send to Customer
                    </button>
                  </>
                )}
              </div>
            </div>

            {/* Quick Stats */}
            <div className="bg-blue-50 rounded-lg p-4">
              <h3 className="font-medium text-blue-900 mb-2">Quick Stats</h3>
              <div className="text-sm space-y-1">
                <div className="flex justify-between">
                  <span>Total Items:</span>
                  <span>{selectedItems.length}</span>
                </div>
                <div className="flex justify-between">
                  <span>Add-ons:</span>
                  <span>{selectedAddons.length}</span>
                </div>
                <div className="flex justify-between">
                  <span>Proposal Number:</span>
                  <span>{proposal.proposal_number}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Send Proposal Modal */}
        {showSendModal && (
          <SendProposal
            proposalId={proposal.id}
            proposalNumber={proposal.proposal_number}
            customer={proposal.customers}
            total={proposal.total}
            onSent={() => {
              setShowSendModal(false)
              window.location.reload()
            }}
            onCancel={() => setShowSendModal(false)}
          />
        )}
      </div>
    </div>
  )
}