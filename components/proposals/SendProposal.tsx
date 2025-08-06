'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { X } from 'lucide-react'

interface SendProposalProps {
  proposalId: string
  customerEmail: string
  proposalNumber: string
  onClose: () => void
  onSuccess: () => void
}

export default function SendProposal({
  proposalId,
  customerEmail,
  proposalNumber,
  onClose,
  onSuccess
}: SendProposalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const supabase = createClient()

  const handleSend = async () => {
    setIsLoading(true)
    setError(null)

    try {
      // First ensure the proposal has a customer_view_token
      const { data: proposal, error: fetchError } = await supabase
        .from('proposals')
        .select('customer_view_token')
        .eq('id', proposalId)
        .single()

      if (fetchError) throw fetchError

      let token = proposal.customer_view_token

      // Generate token if missing
      if (!token) {
        token = crypto.randomUUID()
        const { error: updateError } = await supabase
          .from('proposals')
          .update({ customer_view_token: token })
          .eq('id', proposalId)

        if (updateError) throw updateError
      }

      // Send the proposal
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId,
          customerEmail,
          proposalNumber,
          token
        })
      })

      if (!response.ok) {
        throw new Error('Failed to send proposal')
      }

      // Update proposal status
      const { error: statusError } = await supabase
        .from('proposals')
        .update({ status: 'sent' })
        .eq('id', proposalId)

      if (statusError) throw statusError

      onSuccess()
    } catch (err: any) {
      console.error('Error sending proposal:', err)
      setError(err.message || 'Failed to send proposal')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Send Proposal</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X size={24} />
          </button>
        </div>

        <div className="mb-4">
          <p className="text-gray-600">
            Send proposal #{proposalNumber} to:
          </p>
          <p className="font-medium">{customerEmail}</p>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
            {error}
          </div>
        )}

        <div className="flex gap-3">
          <button
            onClick={handleSend}
            disabled={isLoading}
            className="flex-1 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isLoading ? 'Sending...' : 'Send Proposal'}
          </button>
          <button
            onClick={onClose}
            className="flex-1 bg-gray-200 text-gray-800 px-4 py-2 rounded hover:bg-gray-300"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  )
}
