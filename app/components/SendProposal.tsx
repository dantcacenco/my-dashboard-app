'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { XMarkIcon } from '@heroicons/react/24/outline'

interface SendProposalProps {
  proposalId: string
  proposalNumber: string
  customer: {
    id: string
    name: string
    email: string
  }
  total: number
  onClose: () => void
  onSent: () => void
}

export default function SendProposal({ proposalId, proposalNumber, customer, total, onClose, onSent }: SendProposalProps) {
  const [sending, setSending] = useState(false)
  const [email, setEmail] = useState(customer.email || '')
  const [message, setMessage] = useState(
    `Hi ${customer.name},\n\nPlease find attached your proposal #${proposalNumber}.\n\nYou can review and approve the proposal by clicking the link below.\n\nThank you for your business!`
  )
  const supabase = createClient()

  const handleSend = async () => {
    if (!email) {
      alert('Please enter an email address')
      return
    }

    setSending(true)
    try {
      // First, get the customer_view_token
      const { data: proposal, error: fetchError } = await supabase
        .from('proposals')
        .select('customer_view_token')
        .eq('id', proposalId)
        .single()

      if (fetchError || !proposal?.customer_view_token) {
        throw new Error('Failed to get proposal token')
      }

      // Send the email
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId,
          proposalNumber,
          customerName: customer.name,
          customerEmail: email,
          message,
          total,
          viewLink: `${window.location.origin}/proposal/view/${proposal.customer_view_token}`
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to send proposal')
      }

      // Update proposal status to 'sent'
      const { error: updateError } = await supabase
        .from('proposals')
        .update({ 
          status: 'sent',
          sent_at: new Date().toISOString()
        })
        .eq('id', proposalId)

      if (updateError) {
        console.error('Error updating proposal status:', updateError)
      }

      // Log activity
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'proposal_sent',
          description: `Proposal sent to ${email}`
        })

      alert('Proposal sent successfully!')
      onSent()
    } catch (error) {
      console.error('Error sending proposal:', error)
      alert('Failed to send proposal. Please try again.')
    } finally {
      setSending(false)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full">
        <div className="flex justify-between items-start mb-4">
          <h3 className="text-lg font-medium text-gray-900">Send Proposal</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <div className="mb-4">
          <p className="text-sm text-gray-600 mb-2">
            Sending Proposal #{proposalNumber} - {formatCurrency(total)}
          </p>
          <p className="text-sm text-gray-600">
            To: {customer.name}
          </p>
        </div>

        <div className="mb-4">
          <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
            Email Address
          </label>
          <input
            type="email"
            id="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="customer@example.com"
          />
        </div>

        <div className="mb-6">
          <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-1">
            Message
          </label>
          <textarea
            id="message"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            rows={6}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex gap-3">
          <button
            onClick={handleSend}
            disabled={sending}
            className="flex-1 bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400"
          >
            {sending ? 'Sending...' : 'Send Proposal'}
          </button>
          <button
            onClick={onClose}
            className="flex-1 bg-gray-200 text-gray-800 px-4 py-2 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  )
}
