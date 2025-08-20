'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

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
  customers: any
  proposal_items: any[]
  customer_view_token: string
}

interface CustomerProposalViewProps {
  proposal: ProposalData
  token: string
}

export default function CustomerProposalView({ proposal: initialProposal, token }: CustomerProposalViewProps) {
  const router = useRouter()
  const supabase = createClient()
  
  // Initialize selected add-ons from the proposal
  const [selectedAddons, setSelectedAddons] = useState<Set<string>>(
    new Set(initialProposal.proposal_items?.filter(item => item.is_addon && item.is_selected).map(item => item.id))
  )
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState('')

  // Separate services and add-ons
  const services = initialProposal.proposal_items?.filter(item => !item.is_addon) || []
  const addons = initialProposal.proposal_items?.filter(item => item.is_addon) || []

  // Toggle addon selection
  const toggleAddon = (addonId: string) => {
    const newSelected = new Set(selectedAddons)
    if (newSelected.has(addonId)) {
      newSelected.delete(addonId)
    } else {
      newSelected.add(addonId)
    }
    setSelectedAddons(newSelected)
  }

  // Calculate totals based on selections
  const calculateTotals = () => {
    // Services are always included
    const servicesTotal = services.reduce((sum: number, item: any) => 
      sum + (item.total_price || 0), 0
    )
    
    // Only selected add-ons
    const addonsTotal = addons
      .filter(item => selectedAddons.has(item.id))
      .reduce((sum: number, item: any) => sum + (item.total_price || 0), 0)
    
    const subtotal = servicesTotal + addonsTotal
    const taxAmount = subtotal * (initialProposal.tax_rate || 0)
    const total = subtotal + taxAmount
    
    return { servicesTotal, addonsTotal, subtotal, taxAmount, total }
  }

  const totals = calculateTotals()

  // Handle proposal approval
  const handleApprove = async () => {
    setIsProcessing(true)
    setError('')

    try {
      // Update selected add-ons in the database
      for (const addon of addons) {
        await supabase
          .from('proposal_items')
          .update({ is_selected: selectedAddons.has(addon.id) })
          .eq('id', addon.id)
      }

      // Update proposal totals and status
      await supabase
        .from('proposals')
        .update({
          subtotal: totals.subtotal,
          tax_amount: totals.taxAmount,
          total: totals.total,
          status: 'accepted',
          accepted_at: new Date().toISOString()
        })
        .eq('id', initialProposal.id)

      // Create payment session
      const response = await fetch('/api/create-payment-session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: initialProposal.id,
          amount: totals.total,
          customerEmail: initialProposal.customers?.email,
          proposalNumber: initialProposal.proposal_number,
          selectedAddons: Array.from(selectedAddons)
        })
      })

      if (!response.ok) {
        throw new Error('Failed to create payment session')
      }

      const { url } = await response.json()
      
      if (url) {
        // Redirect to Stripe checkout
        window.location.href = url
      } else {
        // If no payment URL, just show success
        router.push(`/proposal/payment-success?proposal=${initialProposal.id}`)
      }
    } catch (err) {
      console.error('Error approving proposal:', err)
      setError('Failed to approve proposal. Please try again.')
      setIsProcessing(false)
    }
  }

  const handleReject = async () => {
    if (!confirm('Are you sure you want to reject this proposal?')) return

    setIsProcessing(true)
    try {
      await supabase
        .from('proposals')
        .update({
          status: 'rejected',
          rejected_at: new Date().toISOString()
        })
        .eq('id', initialProposal.id)

      alert('Proposal has been rejected.')
      router.refresh()
    } catch (err) {
      console.error('Error rejecting proposal:', err)
      setError('Failed to reject proposal.')
    } finally {
      setIsProcessing(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                {initialProposal.title}
              </h1>
              <p className="text-gray-600 mt-1">
                Proposal #{initialProposal.proposal_number}
              </p>
              {initialProposal.description && (
                <p className="text-gray-700 mt-3">{initialProposal.description}</p>
              )}
            </div>
            <div className="text-right">
              <span className="inline-block px-3 py-1 rounded-full text-sm font-semibold bg-blue-100 text-blue-800">
                {initialProposal.status}
              </span>
            </div>
          </div>
        </div>

        {/* Customer Info */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h2 className="text-lg font-semibold mb-4">Customer Information</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Name</p>
              <p className="font-medium">{initialProposal.customers?.name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Email</p>
              <p className="font-medium">{initialProposal.customers?.email}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Phone</p>
              <p className="font-medium">{initialProposal.customers?.phone || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Address</p>
              <p className="font-medium">{initialProposal.customers?.address || '-'}</p>
            </div>
          </div>
        </div>

        {/* Services */}
        {services.length > 0 && (
          <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
            <h2 className="text-lg font-semibold mb-4">Services</h2>
            <div className="space-y-3">
              {services.map((item: any) => (
                <div key={item.id} className="border rounded-lg p-4 bg-gray-50">
                  <div className="flex justify-between">
                    <div className="flex-1">
                      <h3 className="font-medium">{item.name}</h3>
                      <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                      <p className="text-sm text-gray-500 mt-2">
                        Qty: {item.quantity} × ${item.unit_price?.toFixed(2)}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold text-lg">${item.total_price?.toFixed(2)}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Optional Add-ons */}
        {addons.length > 0 && (
          <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
            <h2 className="text-lg font-semibold mb-4">Optional Add-ons</h2>
            <p className="text-sm text-gray-600 mb-4">
              Select any additional services you'd like to include:
            </p>
            <div className="space-y-3">
              {addons.map((item: any) => (
                <div 
                  key={item.id} 
                  className={`border rounded-lg p-4 cursor-pointer transition-all ${
                    selectedAddons.has(item.id) 
                      ? 'bg-orange-50 border-orange-300' 
                      : 'bg-gray-50 border-gray-200 opacity-75'
                  }`}
                  onClick={() => toggleAddon(item.id)}
                >
                  <div className="flex items-start">
                    <input
                      type="checkbox"
                      checked={selectedAddons.has(item.id)}
                      onChange={() => toggleAddon(item.id)}
                      className="mt-1 mr-3 w-4 h-4 text-orange-600 focus:ring-orange-500"
                      onClick={(e) => e.stopPropagation()}
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h3 className="font-medium">{item.name}</h3>
                        <span className="text-xs bg-orange-200 text-orange-800 px-2 py-1 rounded">
                          Add-on
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                      <p className="text-sm text-gray-500 mt-2">
                        Qty: {item.quantity} × ${item.unit_price?.toFixed(2)}
                      </p>
                    </div>
                    <div className="text-right ml-4">
                      <p className={`font-bold text-lg ${
                        selectedAddons.has(item.id) ? 'text-green-600' : 'text-gray-400'
                      }`}>
                        ${item.total_price?.toFixed(2)}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Totals */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h2 className="text-lg font-semibold mb-4">Total</h2>
          <div className="space-y-2">
            <div className="flex justify-between">
              <span>Services:</span>
              <span>${totals.servicesTotal.toFixed(2)}</span>
            </div>
            {totals.addonsTotal > 0 && (
              <div className="flex justify-between text-orange-600">
                <span>Selected Add-ons:</span>
                <span>+${totals.addonsTotal.toFixed(2)}</span>
              </div>
            )}
            <div className="flex justify-between font-medium pt-2 border-t">
              <span>Subtotal:</span>
              <span>${totals.subtotal.toFixed(2)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Tax ({(initialProposal.tax_rate * 100).toFixed(1)}%):</span>
              <span>${totals.taxAmount.toFixed(2)}</span>
            </div>
            <div className="flex justify-between font-bold text-xl pt-2 border-t">
              <span>Total:</span>
              <span className="text-green-600">${totals.total.toFixed(2)}</span>
            </div>
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4 mb-6">
            {error}
          </div>
        )}

        {/* Action Buttons */}
        {initialProposal.status === 'sent' && (
          <div className="flex gap-4">
            <button
              onClick={handleApprove}
              disabled={isProcessing}
              className="flex-1 bg-green-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {isProcessing ? 'Processing...' : '✓ Approve Proposal'}
            </button>
            <button
              onClick={handleReject}
              disabled={isProcessing}
              className="flex-1 bg-red-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-red-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              ✗ Reject Proposal
            </button>
          </div>
        )}

        {initialProposal.status === 'accepted' && (
          <div className="bg-green-50 border border-green-200 text-green-700 rounded-lg p-4 text-center">
            <p className="font-semibold">This proposal has been accepted.</p>
          </div>
        )}

        {initialProposal.status === 'rejected' && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4 text-center">
            <p className="font-semibold">This proposal has been rejected.</p>
          </div>
        )}
      </div>
    </div>
  )
}
