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
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Service Pro HVAC</h1>
          <p className="text-gray-600">123 Main Street, Anytown, USA 12345</p>
          <p className="text-gray-600">Phone: (555) 123-4567 | Email: info@servicepro.com</p>
        </div>

        {/* Proposal Header */}
        <div className="mb-8 pb-4 border-b">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-1">PROPOSAL</h2>
              <p className="text-gray-600">#{proposal.proposal_number}</p>
              <p className="text-gray-600">{formatDate(proposal.created_at)}</p>
            </div>
            <div className="text-right">
              <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(proposal.status)}`}>
                {proposal.status.toUpperCase()}
              </span>
            </div>
          </div>
        </div>

        {/* Customer Information */}
        <div className="mb-8">
          <h3 className="text-lg font-semibold text-gray-900 mb-3">Bill To:</h3>
          <div className="text-gray-600">
            <p className="font-semibold text-gray-900">{proposal.customers.name}</p>
            <p>{proposal.customers.email}</p>
            <p>{proposal.customers.phone}</p>
            <p>{proposal.customers.address}</p>
          </div>
        </div>

        {/* Proposal Details */}
        <div className="mb-8">
          <h3 className="text-xl font-semibold text-gray-900 mb-2">{proposal.title}</h3>
          {proposal.description && (
            <p className="text-gray-600 whitespace-pre-wrap">{proposal.description}</p>
          )}
        </div>

        {/* Line Items */}
        <div className="mb-8">
          <table className="w-full">
            <thead>
              <tr className="border-b">
                <th className="text-left py-2">Item</th>
                <th className="text-center py-2">Qty</th>
                <th className="text-right py-2">Price</th>
                <th className="text-right py-2">Total</th>
              </tr>
            </thead>
            <tbody>
              {selectedItems.map((item, index) => (
                <tr key={item.id} className={index < selectedItems.length - 1 ? 'border-b' : ''}>
                  <td className="py-2">
                    <div>
                      <p className="font-medium">{item.name}</p>
                      {item.description && (
                        <p className="text-sm text-gray-600">{item.description}</p>
                      )}
                    </div>
                  </td>
                  <td className="text-center py-2">{item.quantity}</td>
                  <td className="text-right py-2">{formatCurrency(item.unit_price)}</td>
                  <td className="text-right py-2">{formatCurrency(item.total_price)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Add-ons */}
        {selectedAddons.length > 0 && (
          <div className="mb-8">
            <h4 className="font-semibold text-gray-900 mb-3">Selected Add-ons</h4>
            <table className="w-full">
              <tbody>
                {selectedAddons.map((addon, index) => (
                  <tr key={addon.id} className={index < selectedAddons.length - 1 ? 'border-b' : ''}>
                    <td className="py-2">
                      <div>
                        <p className="font-medium">{addon.name}</p>
                        {addon.description && (
                          <p className="text-sm text-gray-600">{addon.description}</p>
                        )}
                      </div>
                    </td>
                    <td className="text-center py-2">{addon.quantity}</td>
                    <td className="text-right py-2">{formatCurrency(addon.unit_price)}</td>
                    <td className="text-right py-2">{formatCurrency(addon.total_price)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Totals */}
        <div className="border-t pt-4">
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-gray-600">Subtotal</span>
              <span className="font-medium">{formatCurrency(proposal.subtotal)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Tax ({(proposal.tax_rate * 100).toFixed(1)}%)</span>
              <span className="font-medium">{formatCurrency(proposal.tax_amount)}</span>
            </div>
            <div className="flex justify-between border-t pt-2">
              <span className="text-lg font-semibold">Total</span>
              <span className="text-lg font-semibold">{formatCurrency(proposal.total)}</span>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-12 pt-8 border-t text-center text-gray-600 text-sm">
          <p>Thank you for considering Service Pro HVAC for your needs.</p>
          <p>This proposal is valid for 30 days from the date above.</p>
        </div>

        {/* Close Print View Button (hidden in print) */}
        <div className="mt-8 print:hidden">
          <button
            onClick={() => setShowPrintView(false)}
            className="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
          >
            Close Print View
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="mb-6 flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Proposal #{proposal.proposal_number}</h1>
          <p className="text-gray-600">Created on {formatDate(proposal.created_at)}</p>
        </div>
        <div className="flex items-center gap-4">
          <span className={`px-3 py-1 rounded-full text-sm font-semibold ${getStatusColor(proposal.status)}`}>
            {proposal.status.charAt(0).toUpperCase() + proposal.status.slice(1)}
          </span>
          {userRole === 'admin' && (
            <div className="flex gap-2">
              {proposal.status === 'draft' && (
                <>
                  <Link
                    href={`/proposals/${proposal.id}/edit`}
                    className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                  >
                    Edit
                  </Link>
                  <button
                    onClick={() => setShowSendModal(true)}
                    className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
                  >
                    Send Proposal
                  </button>
                </>
              )}
              <button
                onClick={() => setShowPrintView(true)}
                className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
              >
                Print
              </button>
              <button
                onClick={handlePrint}
                className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
              >
                Download PDF
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Customer Information */}
      <div className="bg-white rounded-lg shadow mb-6">
        <div className="p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Customer Information</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Name</p>
              <p className="font-medium">{proposal.customers.name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Email</p>
              <p className="font-medium">{proposal.customers.email}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Phone</p>
              <p className="font-medium">{proposal.customers.phone}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Address</p>
              <p className="font-medium">{proposal.customers.address}</p>
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
                {selectedItems.map((item) => (
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
            </table>
          </div>
        </div>
      </div>

      {/* Add-ons */}
      {selectedAddons.length > 0 && (
        <div className="bg-white rounded-lg shadow mb-6">
          <div className="p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Selected Add-ons</h2>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3">Add-on</th>
                    <th className="text-center py-3">Quantity</th>
                    <th className="text-right py-3">Unit Price</th>
                    <th className="text-right py-3">Total</th>
                  </tr>
                </thead>
                <tbody>
                  {selectedAddons.map((addon) => (
                    <tr key={addon.id} className="border-b">
                      <td className="py-3">
                        <div>
                          <p className="font-medium">{addon.name}</p>
                          {addon.description && (
                            <p className="text-sm text-gray-600">{addon.description}</p>
                          )}
                        </div>
                      </td>
                      <td className="text-center py-3">{addon.quantity}</td>
                      <td className="text-right py-3">{formatCurrency(addon.unit_price)}</td>
                      <td className="text-right py-3">{formatCurrency(addon.total_price)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Pricing Summary */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Pricing Summary</h2>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-gray-600">Subtotal</span>
              <span className="font-medium">{formatCurrency(proposal.subtotal)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Tax ({(proposal.tax_rate * 100).toFixed(1)}%)</span>
              <span className="font-medium">{formatCurrency(proposal.tax_amount)}</span>
            </div>
            <div className="flex justify-between border-t pt-3">
              <span className="text-lg font-semibold">Total</span>
              <span className="text-lg font-semibold">{formatCurrency(proposal.total)}</span>
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
            router.refresh()
          }}
          onCancel={() => setShowSendModal(false)}
        />
      )}
    </div>
  )
}
