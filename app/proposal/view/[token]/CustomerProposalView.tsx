'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import PaymentMethods from './PaymentMethods'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface ProposalItem {
  id: string
  name: string
  description: string
  quantity: number
  unit_price: number
  total_price: number
  is_addon: boolean
  is_selected: boolean
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
  customers: Customer
  proposal_items: ProposalItem[]
}

interface CustomerProposalViewProps {
  proposal: ProposalData
}

export default function CustomerProposalView({ proposal: initialProposal }: CustomerProposalViewProps) {
  const [proposal, setProposal] = useState(initialProposal)
  const [isApproving, setIsApproving] = useState(false)
  const [isRejecting, setIsRejecting] = useState(false)
  const [showApprovalForm, setShowApprovalForm] = useState(false)
  const [showRejectionForm, setShowRejectionForm] = useState(false)
  const [customerNotes, setCustomerNotes] = useState('')

  const supabase = createClient()

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

  // Separate selected items and add-ons
  const selectedItems = proposal.proposal_items
    .filter(item => !item.is_addon && item.is_selected)
  
  const selectedAddons = proposal.proposal_items
    .filter(item => item.is_addon && item.is_selected)

  const handleApprove = async () => {
    setIsApproving(true)
    
    try {
      // Update proposal status
      await supabase
        .from('proposals')
        .update({ 
          status: 'approved',
          approved_at: new Date().toISOString(),
          customer_notes: customerNotes || null
        })
        .eq('id', proposal.id)

      // Log the approval
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposal.id,
          activity_type: 'approved_by_customer',
          description: `Proposal approved by ${proposal.customers.name}`,
          metadata: {
            customer_email: proposal.customers.email,
            customer_notes: customerNotes,
            approved_at: new Date().toISOString()
          }
        })

      // Send notification email to business
      await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposal_id: proposal.id,
          proposal_number: proposal.proposal_number,
          proposal_title: proposal.title,
          customer_name: proposal.customers.name,
          customer_email: proposal.customers.email,
          total_amount: proposal.total,
          customer_notes: customerNotes,
          action_type: 'approved'
        })
      })

      // Update the local proposal state to reflect the approval
      setProposal({
        ...proposal,
        status: 'approved'
      })

      setShowApprovalForm(false)
      setCustomerNotes('')
      
    } catch (error) {
      console.error('Error approving proposal:', error)
      alert('There was an error approving the proposal. Please try again or contact us directly.')
    } finally {
      setIsApproving(false)
    }
  }

  const handleReject = async () => {
    setIsRejecting(true)
    
    try {
      // Update proposal status
      await supabase
        .from('proposals')
        .update({ 
          status: 'rejected',
          rejected_at: new Date().toISOString(),
          customer_notes: customerNotes || null
        })
        .eq('id', proposal.id)

      // Log the rejection
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposal.id,
          activity_type: 'rejected_by_customer',
          description: `Proposal rejected by ${proposal.customers.name}`,
          metadata: {
            customer_email: proposal.customers.email,
            customer_notes: customerNotes,
            rejected_at: new Date().toISOString()
          }
        })

      // Send notification email to business
      await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposal_id: proposal.id,
          proposal_number: proposal.proposal_number,
          proposal_title: proposal.title,
          customer_name: proposal.customers.name,
          customer_email: proposal.customers.email,
          total_amount: proposal.total,
          customer_notes: customerNotes,
          action_type: 'rejected'
        })
      })

      alert('We have received your response. Thank you for your time. We may contact you to discuss alternatives.')
      setShowRejectionForm(false)
      
    } catch (error) {
      console.error('Error rejecting proposal:', error)
      alert('There was an error processing your response. Please try again or contact us directly.')
    } finally {
      setIsRejecting(false)
    }
  }

  const handlePrint = () => {
    window.print()
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 print:py-0">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 print:px-0">
        
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm p-8 mb-6 print:shadow-none print:rounded-none">
          <div className="flex justify-between items-start mb-6">
            <div>
              <h1 className="text-3xl font-bold text-blue-600 print:text-black">Service Pro</h1>
              <p className="text-gray-600 print:text-gray-800">Professional HVAC Services</p>
              <div className="mt-2 text-sm text-gray-600 print:text-gray-800">
                <p>Phone: (555) 123-4567</p>
                <p>Email: info@servicepro.com</p>
              </div>
            </div>
            <div className="text-right">
              <h2 className="text-2xl font-bold print:text-black">PROPOSAL</h2>
              <p className="text-lg font-semibold text-blue-600 print:text-black">{proposal.proposal_number}</p>
              <p className="text-sm text-gray-600 print:text-gray-800">{formatDate(proposal.created_at)}</p>
            </div>
          </div>

          {/* Customer Information */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
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
              <h3 className="font-semibold text-gray-900 mb-2">Project Details:</h3>
              <div className="text-gray-700">
                <p><span className="font-medium">Project:</span> {proposal.title}</p>
                {proposal.description && (
                  <div className="mt-2">
                    <p className="font-medium">Description:</p>
                    <p className="text-sm mt-1">{proposal.description}</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Services Table */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6 print:shadow-none print:rounded-none">
          <h3 className="text-lg font-semibold mb-4">Services & Materials</h3>
          <div className="overflow-x-auto">
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
        </div>

        {/* Add-ons if any */}
        {selectedAddons.length > 0 && (
          <div className="bg-white rounded-lg shadow-sm p-6 mb-6 print:shadow-none print:rounded-none">
            <h3 className="text-lg font-semibold mb-4">Additional Services (Included)</h3>
            <div className="overflow-x-auto">
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
          </div>
        )}

        {/* Totals */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6 print:shadow-none print:rounded-none">
          <div className="flex justify-end">
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
                  <span className="text-green-600">{formatCurrency(proposal.total)}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Terms & Conditions */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6 print:shadow-none print:rounded-none">
          <h3 className="font-semibold text-gray-900 mb-3">Terms & Conditions</h3>
          <div className="text-sm text-gray-600 space-y-2">
            <p>• This proposal is valid for 30 days from the date above</p>
            <p>• Work will begin upon signed approval and initial payment</p>
            <p>• All materials and workmanship are guaranteed for 1 year</p>
            <p>• Payment terms: 50% deposit, 30% at substantial completion, 20% final payment</p>
            <p>• Any changes to the scope of work may result in additional charges</p>
          </div>
        </div>

        {/* Action Buttons or Payment Methods - Dynamic based on status */}
        {proposal.status === 'approved' ? (
          <PaymentMethods
            proposalId={proposal.id}
            proposalNumber={proposal.proposal_number}
            customerName={proposal.customers.name}
            customerEmail={proposal.customers.email}
            totalAmount={proposal.total}
            depositAmount={proposal.total * 0.5} // 50% deposit
            onPaymentSuccess={() => window.location.reload()}
          />
        ) : proposal.status !== 'rejected' ? (
          <div className="bg-white rounded-lg shadow-sm p-6 mb-6 print:hidden">
            <h3 className="font-semibold text-gray-900 mb-4">Your Response</h3>
            <div className="flex gap-4 mb-4">
              <button
                onClick={() => setShowApprovalForm(true)}
                className="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
              >
                Approve Proposal
              </button>
              <button
                onClick={() => setShowRejectionForm(true)}
                className="flex-1 px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium"
              >
                Decline Proposal
              </button>
              <button
                onClick={handlePrint}
                className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium"
              >
                Print/Save PDF
              </button>
            </div>
          </div>
        ) : null}

        {/* Status Message */}
        {proposal.status === 'approved' && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-6 print:hidden">
            <div className="flex items-center">
              <svg className="w-5 h-5 text-green-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <span className="text-green-800 font-medium">This proposal has been approved. We will contact you soon!</span>
            </div>
          </div>
        )}

        {proposal.status === 'rejected' && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6 print:hidden">
            <div className="flex items-center">
              <svg className="w-5 h-5 text-red-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
              <span className="text-red-800 font-medium">This proposal was declined. Thank you for your consideration.</span>
            </div>
          </div>
        )}

        {/* Approval Form Modal */}
        {showApprovalForm && (
          <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
            <div className="relative top-20 mx-auto p-5 border w-full max-w-md shadow-lg rounded-md bg-white">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Approve Proposal</h3>
              <p className="text-gray-600 mb-4">
                By approving this proposal, you agree to the terms and pricing outlined above.
              </p>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Additional Notes (Optional)
                </label>
                <textarea
                  value={customerNotes}
                  onChange={(e) => setCustomerNotes(e.target.value)}
                  rows={3}
                  className="w-full p-2 border border-gray-300 rounded-md"
                  placeholder="Any special requests or notes..."
                />
              </div>
              <div className="flex gap-3">
                <button
                  onClick={handleApprove}
                  disabled={isApproving}
                  className="flex-1 px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:bg-gray-400"
                >
                  {isApproving ? 'Approving...' : 'Confirm Approval'}
                </button>
                <button
                  onClick={() => setShowApprovalForm(false)}
                  className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Rejection Form Modal */}
        {showRejectionForm && (
          <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
            <div className="relative top-20 mx-auto p-5 border w-full max-w-md shadow-lg rounded-md bg-white">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Decline Proposal</h3>
              <p className="text-gray-600 mb-4">
                We'd appreciate any feedback about why this proposal doesn't meet your needs.
              </p>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Reason for Declining (Optional)
                </label>
                <textarea
                  value={customerNotes}
                  onChange={(e) => setCustomerNotes(e.target.value)}
                  rows={3}
                  className="w-full p-2 border border-gray-300 rounded-md"
                  placeholder="Please let us know how we can improve..."
                />
              </div>
              <div className="flex gap-3">
                <button
                  onClick={handleReject}
                  disabled={isRejecting}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 disabled:bg-gray-400"
                >
                  {isRejecting ? 'Processing...' : 'Confirm Decline'}
                </button>
                <button
                  onClick={() => setShowRejectionForm(false)}
                  className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Footer */}
        <div className="text-center text-gray-500 text-sm py-8 print:py-4">
          <p>© 2025 Service Pro - Professional HVAC Services</p>
          <p>Questions? Contact us at (555) 123-4567 or info@servicepro.com</p>
        </div>
      </div>
    </div>
  )
}