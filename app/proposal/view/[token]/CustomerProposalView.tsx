'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Check, X, Calendar, Mail, Phone, MapPin, Plus } from 'lucide-react'

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
  deposit_percentage: number
  progress_percentage: number
  final_percentage: number
  deposit_paid_at: string | null
  progress_paid_at: string | null
  final_paid_at: string | null
  deposit_amount: number | null
  progress_payment_amount: number | null
  final_payment_amount: number | null
  total_paid: number
  payment_stage: string | null
  created_at: string
  valid_until: string | null
}

interface CustomerProposalViewProps {
  proposal: ProposalData
  token: string
}

export default function CustomerProposalView({ proposal: initialProposal, token }: CustomerProposalViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [proposal, setProposal] = useState(initialProposal)
  const [selectedAddons, setSelectedAddons] = useState<Set<string>>(
    new Set(initialProposal.proposal_items?.filter(item => item.is_addon && item.is_selected).map(item => item.id))
  )
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState('')

  // Refresh proposal data
  const refreshProposal = async () => {
    const { data } = await supabase
      .from('proposals')
      .select(`
        *,
        customers!inner(*),
        proposal_items(*)
      `)
      .eq('customer_view_token', token)
      .single()
    
    if (data) {
      setProposal(data)
    }
  }

  useEffect(() => {
    // Poll for updates every 5 seconds if payment is in progress
    if (proposal.status === 'approved') {
      const interval = setInterval(refreshProposal, 5000)
      return () => clearInterval(interval)
    }
  }, [proposal.status, proposal.payment_stage])

  // Separate services and add-ons
  const services = proposal.proposal_items?.filter(item => !item.is_addon) || []
  const addons = proposal.proposal_items?.filter(item => item.is_addon) || []

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

  // Calculate totals
  const calculateTotals = () => {
    const servicesTotal = services.reduce((sum: number, item: any) => 
      sum + (item.total_price || 0), 0
    )
    
    const addonsTotal = addons
      .filter(item => selectedAddons.has(item.id))
      .reduce((sum: number, item: any) => sum + (item.total_price || 0), 0)
    
    const subtotal = servicesTotal + addonsTotal
    const taxAmount = subtotal * (proposal.tax_rate || 0)
    const total = subtotal + taxAmount
    
    return { servicesTotal, addonsTotal, subtotal, taxAmount, total }
  }

  const totals = calculateTotals()

  // Handle proposal approval - FIXED with proper calculations
  const handleApprove = async () => {
    setIsProcessing(true)
    setError('')

    try {
      // Update selected add-ons
      for (const addon of addons) {
        const { error: addonError } = await supabase
          .from('proposal_items')
          .update({ is_selected: selectedAddons.has(addon.id) })
          .eq('id', addon.id)
        
        if (addonError) {
          console.error('Error updating addon:', addonError)
        }
      }

      // Calculate payment amounts with proper rounding
      const total = Math.round(totals.total * 100) / 100
      const depositAmount = Math.round((total * 0.5) * 100) / 100
      const progressAmount = Math.round((total * 0.3) * 100) / 100
      const finalAmount = Math.round((total * 0.2) * 100) / 100

      // Ensure amounts add up exactly to total (handle rounding)
      const sumOfPayments = depositAmount + progressAmount + finalAmount
      const difference = Math.round((total - sumOfPayments) * 100) / 100
      const adjustedFinalAmount = finalAmount + difference

      console.log('Approval calculations:', {
        subtotal: totals.subtotal,
        tax: totals.taxAmount,
        total,
        deposit: depositAmount,
        progress: progressAmount,
        final: adjustedFinalAmount,
        sum: depositAmount + progressAmount + adjustedFinalAmount
      })

      // Update proposal status to accepted
      const updateData = {
        status: 'approved',
        subtotal: Math.round(totals.subtotal * 100) / 100,
        tax_amount: Math.round(totals.taxAmount * 100) / 100,
        total: total,
        deposit_amount: depositAmount,
        progress_payment_amount: progressAmount,
        final_payment_amount: adjustedFinalAmount,
        // payment_stage removed - may not exist or have constraint
        approved_at: new Date().toISOString()
      }

      console.log('Updating proposal with:', updateData)

      const { data: updateResult, error: updateError } = await supabase
        .from('proposals')
        .update(updateData)
        .eq('id', proposal.id)
        .select()
        .single()

      if (updateError) {
        console.error('Full update error:', updateError)
        throw new Error(updateError.message || 'Failed to approve proposal')
      }

      console.log('Update successful:', updateResult)

      // Refresh the proposal data to show payment stages
      await refreshProposal()
      
    } catch (err: any) {
      console.error('Approval error:', err)
      setError(err.message || 'Failed to approve proposal. Please try again.')
    } finally {
      setIsProcessing(false)
    }
  }

  // Handle payment for a specific stage
  const handlePayment = async (stage: 'deposit' | 'roughin' | 'final') => {
    setIsProcessing(true)
    setError('')

    try {
      let amount = 0
      let description = ''
      
      switch(stage) {
        case 'deposit':
          amount = proposal.deposit_amount || 0
          description = `50% Deposit for Proposal #${proposal.proposal_number}`
          break
        case 'roughin':
          amount = proposal.progress_payment_amount || 0
          description = `30% Rough-in Payment for Proposal #${proposal.proposal_number}`
          break
        case 'final':
          amount = proposal.final_payment_amount || 0
          description = `20% Final Payment for Proposal #${proposal.proposal_number}`
          break
      }

      // Create payment session
      const response = await fetch('/api/create-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposal_id: proposal.id,
          proposal_number: proposal.proposal_number,
          customer_name: proposal.customers?.name,
          customer_email: proposal.customers?.email,
          amount,
          payment_type: 'card',
          payment_stage: stage,
          description
        })
      })

      const data = await response.json()
      
      if (data.checkout_url) {
        // Redirect to Stripe checkout
        window.location.href = data.checkout_url
      } else {
        throw new Error('No payment URL received')
      }
      
    } catch (err: any) {
      console.error('Payment error:', err)
      setError('Failed to process payment. Please try again.')
      setIsProcessing(false)
    }
  }

  // Handle rejection
  const handleReject = async () => {
    setIsProcessing(true)
    try {
      await supabase
        .from('proposals')
        .update({
          status: 'rejected',
          rejected_at: new Date().toISOString()
        })
        .eq('id', proposal.id)
      
      await refreshProposal()
    } catch (err) {
      setError('Failed to reject proposal')
    } finally {
      setIsProcessing(false)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  // Show payment stages if approved
  if (proposal.status === 'approved') {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-4">
          <div className="bg-white rounded-lg shadow-lg p-8">
            <div className="mb-8">
              <h1 className="text-3xl font-bold mb-2">{proposal.title}</h1>
              <p className="text-gray-600">Proposal #{proposal.proposal_number}</p>
              <div className="mt-4">
                <span className="bg-green-100 text-green-800 px-3 py-1 rounded-full text-sm font-medium">
                  ✓ Approved
                </span>
              </div>
            </div>

            {/* Services Included */}
            {services.length > 0 && (
              <div className="mb-8">
                <h2 className="text-xl font-semibold mb-4">Services Included</h2>
                <div className="border rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Service
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Qty
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Unit Price
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Total
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {services.map((item: any) => (
                        <tr key={item.id}>
                          <td className="px-6 py-4">
                            <div>
                              <div className="font-medium">{item.name}</div>
                              {item.description && (
                                <div className="text-sm text-gray-600 mt-1">{item.description}</div>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center">{item.quantity}</td>
                          <td className="px-6 py-4 text-right">{formatCurrency(item.unit_price)}</td>
                          <td className="px-6 py-4 text-right font-medium">
                            {formatCurrency(item.total_price)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Selected Add-ons */}
            {addons.filter(item => selectedAddons.has(item.id)).length > 0 && (
              <div className="mb-8">
                <h2 className="text-xl font-semibold mb-4">Selected Add-ons</h2>
                <div className="border rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Add-on
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Qty
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Unit Price
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Total
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {addons.filter(item => selectedAddons.has(item.id)).map((addon: any) => (
                        <tr key={addon.id}>
                          <td className="px-6 py-4">
                            <div>
                              <div className="font-medium">{addon.name}</div>
                              {addon.description && (
                                <div className="text-sm text-gray-600 mt-1">{addon.description}</div>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center">{addon.quantity}</td>
                          <td className="px-6 py-4 text-right">{formatCurrency(addon.unit_price)}</td>
                          <td className="px-6 py-4 text-right font-medium">
                            {formatCurrency(addon.total_price)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Approved Total */}
            <div className="bg-green-50 border border-green-200 rounded-lg p-6 mb-8">
              <div className="space-y-3">
                {services.length > 0 && (
                  <div className="flex justify-between">
                    <span className="text-gray-700">Services Total</span>
                    <span className="font-medium">{formatCurrency(totals.servicesTotal)}</span>
                  </div>
                )}
                {totals.addonsTotal > 0 && (
                  <div className="flex justify-between">
                    <span className="text-gray-700">Selected Add-ons</span>
                    <span className="font-medium">{formatCurrency(totals.addonsTotal)}</span>
                  </div>
                )}
                <div className="flex justify-between">
                  <span className="text-gray-700">Subtotal</span>
                  <span className="font-medium">{formatCurrency(totals.subtotal)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-700">Tax ({(proposal.tax_rate * 100).toFixed(1)}%)</span>
                  <span className="font-medium">{formatCurrency(totals.taxAmount)}</span>
                </div>
                <div className="pt-3 border-t border-green-300">
                  <div className="flex justify-between items-center">
                    <span className="text-lg font-semibold text-green-900">Approved Total</span>
                    <span className="text-2xl font-bold text-green-900">{formatCurrency(proposal.total)}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Payment Schedule */}
            <div className="space-y-6">
              <h2 className="text-xl font-semibold mb-4">Payment Schedule</h2>
              
              {/* Deposit */}
              <div className="border rounded-lg p-6">
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="font-semibold">50% Deposit</h3>
                    <p className="text-gray-600 text-sm mt-1">Due upon approval</p>
                    <p className="text-2xl font-bold mt-2">{formatCurrency(proposal.deposit_amount || 0)}</p>
                  </div>
                  {proposal.deposit_paid_at ? (
                    <div className="flex items-center text-green-600">
                      <Check className="h-5 w-5 mr-2" />
                      <span className="font-medium">Paid</span>
                    </div>
                  ) : (
                    <button
                      onClick={() => handlePayment('deposit')}
                      disabled={isProcessing}
                      className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 disabled:opacity-50 font-medium"
                    >
                      Pay Now
                    </button>
                  )}
                </div>
              </div>

              {/* Rough-in */}
              <div className={`border rounded-lg p-6 ${!proposal.deposit_paid_at ? 'opacity-50' : ''}`}>
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="font-semibold">30% Rough-in Payment</h3>
                    <p className="text-gray-600 text-sm mt-1">Due after rough-in inspection</p>
                    <p className="text-2xl font-bold mt-2">{formatCurrency(proposal.progress_payment_amount || 0)}</p>
                  </div>
                  {proposal.progress_paid_at ? (
                    <div className="flex items-center text-green-600">
                      <Check className="h-5 w-5 mr-2" />
                      <span className="font-medium">Paid</span>
                    </div>
                  ) : proposal.deposit_paid_at ? (
                    <button
                      onClick={() => handlePayment('roughin')}
                      disabled={isProcessing}
                      className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 disabled:opacity-50 font-medium"
                    >
                      Pay Now
                    </button>
                  ) : (
                    <span className="text-gray-400 font-medium">Locked</span>
                  )}
                </div>
              </div>

              {/* Final */}
              <div className={`border rounded-lg p-6 ${!proposal.progress_paid_at ? 'opacity-50' : ''}`}>
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="font-semibold">20% Final Payment</h3>
                    <p className="text-gray-600 text-sm mt-1">Due upon completion</p>
                    <p className="text-2xl font-bold mt-2">{formatCurrency(proposal.final_payment_amount || 0)}</p>
                  </div>
                  {proposal.final_paid_at ? (
                    <div className="flex items-center text-green-600">
                      <Check className="h-5 w-5 mr-2" />
                      <span className="font-medium">Paid</span>
                    </div>
                  ) : proposal.progress_paid_at ? (
                    <button
                      onClick={() => handlePayment('final')}
                      disabled={isProcessing}
                      className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 disabled:opacity-50 font-medium"
                    >
                      Pay Now
                    </button>
                  ) : (
                    <span className="text-gray-400 font-medium">Locked</span>
                  )}
                </div>
              </div>
            </div>

            {/* Payment Progress */}
            <div className="mt-8 bg-gray-50 rounded-lg p-6">
              <h3 className="font-semibold mb-3">Payment Progress</h3>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-gray-600">Total Project Cost</span>
                  <span className="font-semibold">{formatCurrency(proposal.total)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Total Paid</span>
                  <span className="font-semibold text-green-600">
                    {formatCurrency(proposal.total_paid || 0)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Remaining Balance</span>
                  <span className="font-semibold">
                    {formatCurrency(proposal.total - (proposal.total_paid || 0))}
                  </span>
                </div>
              </div>
            </div>

            {error && (
              <div className="mt-4 p-4 bg-red-100 text-red-700 rounded">
                {error}
              </div>
            )}
          </div>
        </div>
      </div>
    )
  }

  // Show full proposal with approval/rejection UI if not yet approved
  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        <div className="bg-white rounded-lg shadow-lg">
          {/* Header */}
          <div className="bg-blue-600 text-white p-8 rounded-t-lg">
            <div className="flex justify-between items-start">
              <div>
                <h1 className="text-3xl font-bold mb-2">{proposal.title}</h1>
                <p className="text-blue-100">Proposal #{proposal.proposal_number}</p>
              </div>
              <div className="text-right">
                <p className="text-sm text-blue-100">Created</p>
                <p className="font-semibold">{formatDate(proposal.created_at)}</p>
                {proposal.valid_until && (
                  <>
                    <p className="text-sm text-blue-100 mt-2">Valid Until</p>
                    <p className="font-semibold">{formatDate(proposal.valid_until)}</p>
                  </>
                )}
              </div>
            </div>
          </div>

          <div className="p-8 space-y-8">
            {/* Customer Information */}
            {proposal.customers && (
              <div>
                <h2 className="text-xl font-semibold mb-4">Customer Information</h2>
                <div className="bg-gray-50 rounded-lg p-6">
                  <div className="grid md:grid-cols-2 gap-4">
                    <div>
                      <p className="text-sm text-gray-600 mb-1">Name</p>
                      <p className="font-medium">{proposal.customers.name}</p>
                    </div>
                    {proposal.customers.email && (
                      <div>
                        <p className="text-sm text-gray-600 mb-1">Email</p>
                        <p className="font-medium flex items-center">
                          <Mail className="h-4 w-4 mr-2 text-gray-400" />
                          {proposal.customers.email}
                        </p>
                      </div>
                    )}
                    {proposal.customers.phone && (
                      <div>
                        <p className="text-sm text-gray-600 mb-1">Phone</p>
                        <p className="font-medium flex items-center">
                          <Phone className="h-4 w-4 mr-2 text-gray-400" />
                          {proposal.customers.phone}
                        </p>
                      </div>
                    )}
                    {proposal.customers.address && (
                      <div>
                        <p className="text-sm text-gray-600 mb-1">Service Address</p>
                        <p className="font-medium flex items-center">
                          <MapPin className="h-4 w-4 mr-2 text-gray-400" />
                          {proposal.customers.address}
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Proposal Description */}
            {proposal.description && (
              <div>
                <h2 className="text-xl font-semibold mb-4">Project Description</h2>
                <div className="bg-gray-50 rounded-lg p-6">
                  <p className="text-gray-700 whitespace-pre-wrap">{proposal.description}</p>
                </div>
              </div>
            )}

            {/* Services */}
            {services.length > 0 && (
              <div>
                <h2 className="text-xl font-semibold mb-4">Services Included</h2>
                <div className="border rounded-lg overflow-hidden">
                  <table className="w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Service
                        </th>
                        <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Qty
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Unit Price
                        </th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Total
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {services.map((item: any) => (
                        <tr key={item.id}>
                          <td className="px-6 py-4">
                            <div>
                              <div className="font-medium">{item.name}</div>
                              {item.description && (
                                <div className="text-sm text-gray-600 mt-1">{item.description}</div>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center">{item.quantity}</td>
                          <td className="px-6 py-4 text-right">{formatCurrency(item.unit_price)}</td>
                          <td className="px-6 py-4 text-right font-medium">
                            {formatCurrency(item.total_price)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Optional Add-ons */}
            {addons.length > 0 && (
              <div>
                <h2 className="text-xl font-semibold mb-4">Optional Add-ons</h2>
                <div className="space-y-3">
                  {addons.map((addon: any) => (
                    <div
                      key={addon.id}
                      className={`border rounded-lg p-4 cursor-pointer transition-all ${
                        selectedAddons.has(addon.id)
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                      onClick={() => toggleAddon(addon.id)}
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className={`w-5 h-5 rounded border-2 mr-3 flex items-center justify-center ${
                            selectedAddons.has(addon.id)
                              ? 'bg-blue-500 border-blue-500'
                              : 'border-gray-300'
                          }`}>
                            {selectedAddons.has(addon.id) && (
                              <Check className="h-3 w-3 text-white" />
                            )}
                          </div>
                          <div>
                            <div className="font-medium">{addon.name}</div>
                            {addon.description && (
                              <div className="text-sm text-gray-600 mt-1">{addon.description}</div>
                            )}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="font-semibold">{formatCurrency(addon.total_price)}</div>
                          <div className="text-sm text-gray-500">
                            {addon.quantity} × {formatCurrency(addon.unit_price)}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Totals */}
            <div>
              <h2 className="text-xl font-semibold mb-4">Cost Summary</h2>
              <div className="bg-gray-50 rounded-lg p-6">
                <div className="space-y-3">
                  {services.length > 0 && (
                    <div className="flex justify-between">
                      <span className="text-gray-600">Services Total</span>
                      <span className="font-medium">{formatCurrency(totals.servicesTotal)}</span>
                    </div>
                  )}
                  {totals.addonsTotal > 0 && (
                    <div className="flex justify-between">
                      <span className="text-gray-600">Selected Add-ons</span>
                      <span className="font-medium">{formatCurrency(totals.addonsTotal)}</span>
                    </div>
                  )}
                  <div className="flex justify-between">
                    <span className="text-gray-600">Subtotal</span>
                    <span className="font-medium">{formatCurrency(totals.subtotal)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Tax ({(proposal.tax_rate * 100).toFixed(1)}%)</span>
                    <span className="font-medium">{formatCurrency(totals.taxAmount)}</span>
                  </div>
                  <div className="pt-3 border-t border-gray-300">
                    <div className="flex justify-between">
                      <span className="text-lg font-semibold">Total</span>
                      <span className="text-2xl font-bold text-blue-600">
                        {formatCurrency(totals.total)}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Payment Terms */}
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
              <h3 className="font-semibold mb-3 text-blue-900">Payment Terms</h3>
              <div className="space-y-2 text-sm text-blue-800">
                <p>• 50% deposit due upon approval</p>
                <p>• 30% progress payment due after rough-in inspection</p>
                <p>• 20% final payment due upon project completion</p>
                <p className="pt-2 font-medium">All payments are processed securely through Stripe.</p>
              </div>
            </div>

            {/* Approve/Reject buttons */}
            <div className="flex gap-4 justify-center pt-4">
              <button
                onClick={handleApprove}
                disabled={isProcessing}
                className="bg-green-600 text-white px-8 py-3 rounded-lg hover:bg-green-700 disabled:opacity-50 font-semibold flex items-center"
              >
                <Check className="h-5 w-5 mr-2" />
                Approve Proposal
              </button>
              <button
                onClick={handleReject}
                disabled={isProcessing}
                className="bg-red-600 text-white px-8 py-3 rounded-lg hover:bg-red-700 disabled:opacity-50 font-semibold flex items-center"
              >
                <X className="h-5 w-5 mr-2" />
                Reject Proposal
              </button>
            </div>

            {error && (
              <div className="mt-4 p-4 bg-red-100 text-red-700 rounded">
                {error}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
