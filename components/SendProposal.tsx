'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface SendProposalProps {
  proposalId: string
  proposalNumber: string
  customerEmail?: string
  customerName?: string
  onSent?: () => void
}

export default function SendProposal({
  proposalId,
  proposalNumber,
  customerEmail,
  customerName,
  onSent
}: SendProposalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [emailContent, setEmailContent] = useState('')
  const supabase = createClient()

  const handleSendClick = () => {
    const defaultMessage = `Dear ${customerName || 'Customer'},

We're pleased to present you with Proposal #${proposalNumber} for your HVAC service needs.

Please review the attached proposal and let us know if you have any questions.

Best regards,
Service Pro HVAC Team`

    setEmailContent(defaultMessage)
    setShowModal(true)
  }

  const handleSend = async () => {
    setIsLoading(true)
    
    try {
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId,
          proposalNumber,
          customerEmail,
          customerName,
          message: emailContent
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to send proposal')
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

      alert('Proposal sent successfully!')
      setShowModal(false)
      onSent?.()
    } catch (error: any) {
      console.error('Error sending proposal:', error)
      alert(error.message || 'Failed to send proposal')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <>
      <button
        onClick={handleSendClick}
        className="inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 font-medium"
        disabled={!customerEmail}
      >
        Send Proposal
      </button>

      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4">
            <h3 className="text-lg font-semibold mb-4">Send Proposal</h3>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                To: {customerEmail}
              </label>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Message:
              </label>
              <textarea
                value={emailContent}
                onChange={(e) => setEmailContent(e.target.value)}
                className="w-full p-2 border rounded-md"
                rows={8}
              />
            </div>

            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowModal(false)}
                className="px-4 py-2 text-gray-600 hover:text-gray-800"
                disabled={isLoading}
              >
                Cancel
              </button>
              <button
                onClick={handleSend}
                className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
                disabled={isLoading || !emailContent}
              >
                {isLoading ? 'Sending...' : 'Send'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
