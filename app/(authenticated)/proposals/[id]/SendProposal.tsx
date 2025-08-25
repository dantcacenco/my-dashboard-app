'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Input } from '@/components/ui/input'
import { X, Send } from 'lucide-react'

interface SendProposalProps {
  proposalId: string
  proposalNumber: string
  customerEmail?: string
  customerName?: string
  total: number
  onClose: () => void
  onSuccess: () => void
}

export default function SendProposal({
  proposalId,
  proposalNumber,
  customerEmail,
  customerName,
  total,
  onClose,
  onSuccess
}: SendProposalProps) {
  const [email, setEmail] = useState(customerEmail || '')
  const [message, setMessage] = useState(
    `Please find attached your proposal #${proposalNumber} for HVAC services.\n\nTotal Amount: $${total?.toFixed(2) || '0.00'}\n\nYou can view and approve your proposal by clicking the link in the email.\n\nIf you have any questions, please don't hesitate to contact us.\n\nBest regards,\nYour HVAC Team`
  )
  const [isSending, setIsSending] = useState(false)
  const [error, setError] = useState('')

  const handleSend = async () => {
    // Validate email
    if (!email || !email.includes('@')) {
      setError('Please enter a valid email address')
      return
    }

    setIsSending(true)
    setError('')

    try {
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId,
          proposalNumber,
          email,
          customerName: customerName || 'Customer',
          message,
          total
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to send proposal')
      }

      onSuccess()
      onClose()
    } catch (err: any) {
      console.error('Send error:', err)
      setError(err.message || 'Failed to send proposal')
    } finally {
      setIsSending(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-lg w-full max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">Send Proposal #{proposalNumber}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-100 text-red-700 rounded">
            {error}
          </div>
        )}

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">To:</label>
            <Input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="customer@email.com"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Subject:</label>
            <Input
              value={`Your Proposal #${proposalNumber} is Ready`}
              disabled
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Message:</label>
            <Textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={8}
            />
          </div>
        </div>

        <div className="flex justify-end gap-2 mt-6">
          <Button variant="outline" onClick={onClose} disabled={isSending}>
            Cancel
          </Button>
          <Button onClick={handleSend} disabled={isSending}>
            {isSending ? (
              <>Sending...</>
            ) : (
              <>
                <Send className="h-4 w-4 mr-2" />
                Send
              </>
            )}
          </Button>
        </div>
      </div>
    </div>
  )
}
