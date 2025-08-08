'use client'

import { useState, useEffect } from 'react'
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
  const [proposalToken, setProposalToken] = useState<string>('')
  const supabase = createClient()

  // Fetch the proposal token when component mounts or modal opens
  const fetchProposalToken = async () => {
    const { data, error } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposalId)
      .single()

    if (data?.customer_view_token) {
      setProposalToken(data.customer_view_token)
    } else {
      // Generate a new token if it doesn't exist
      const newToken = crypto.randomUUID()
      await supabase
        .from('proposals')
        .update({ customer_view_token: newToken })
        .eq('id', proposalId)
      setProposalToken(newToken)
    }
  }

  const handleSendClick = async () => {
    // First fetch/generate the token
    await fetchProposalToken()
    
    // Wait a moment for state to update
    setTimeout(() => {
      const baseUrl = window.location.origin
      const viewLink = `${baseUrl}/proposal/view/${proposalToken || 'TOKEN_ERROR'}`
      
      const defaultMessage = `Dear ${customerName || 'Customer'},

Please find attached your proposal #${proposalNumber}.

You can view and approve your proposal by clicking the link below:
${viewLink}

If you have any questions, please don't hesitate to contact us.

Best regards,
Your HVAC Team`

      setEmailContent(defaultMessage)
      setShowModal(true)
    }, 100)
  }

  const handleSend = async () => {
    if (!customerEmail || !emailContent || !proposalId || !proposalNumber) {
      alert('Missing required information. Please check all fields.')
      return
    }

    setIsLoading(true)
    
    try {
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: proposalId,
          proposalNumber: proposalNumber,
          customerEmail: customerEmail,
          customerName: customerName || 'Customer',
          message: emailContent,
          token: proposalToken
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

  // Update email content when token changes
  useEffect(() => {
    if (proposalToken && showModal) {
      const baseUrl = window.location.origin
      const viewLink = `${baseUrl}/proposal/view/${proposalToken}`
      
      setEmailContent(prevContent => 
        prevContent.replace(/https:\/\/[^\s]+generating\.\.\./, viewLink)
        .replace(/TOKEN_ERROR/, proposalToken)
      )
    }
  }, [proposalToken, showModal])

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
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4 max-h-[80vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold">Send Proposal #{proposalNumber}</h3>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                ✕
              </button>
            </div>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                To:
              </label>
              <div className="p-2 bg-gray-50 rounded">
                {customerEmail}
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Subject:
              </label>
              <div className="p-2 bg-gray-50 rounded">
                Your Proposal #{proposalNumber} is Ready
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Message:
              </label>
              <textarea
                value={emailContent}
                onChange={(e) => setEmailContent(e.target.value)}
                className="w-full p-2 border rounded-md"
                rows={10}
              />
            </div>

            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowModal(false)}
                className="px-4 py-2 text-gray-600 hover:text-gray-800 border border-gray-300 rounded-md"
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
