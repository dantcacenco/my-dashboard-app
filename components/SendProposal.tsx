'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { PaperAirplaneIcon } from '@heroicons/react/24/outline'

interface SendProposalProps {
  proposalId: string
  proposalNumber: string
  customerEmail?: string
  customerName?: string
  onSent?: () => void
  variant?: 'button' | 'icon' | 'full'
  buttonText?: string
}

export default function SendProposal({
  proposalId,
  proposalNumber,
  customerEmail,
  customerName,
  onSent,
  variant = 'full',
  buttonText = 'Send Proposal'
}: SendProposalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [emailContent, setEmailContent] = useState('')
  const [proposalToken, setProposalToken] = useState<string>('')
  const [emailTo, setEmailTo] = useState(customerEmail || '')
  const [sendCopy, setSendCopy] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    setEmailTo(customerEmail || '')
  }, [customerEmail])

  const fetchProposalToken = async () => {
    try {
      const { data, error } = await supabase
        .from('proposals')
        .select('customer_view_token')
        .eq('id', proposalId)
        .single()

      if (error) {
        console.error('Error fetching proposal:', error)
        return null
      }

      if (data?.customer_view_token) {
        return data.customer_view_token
      } else {
        const newToken = crypto.randomUUID()
        const { error: updateError } = await supabase
          .from('proposals')
          .update({ customer_view_token: newToken })
          .eq('id', proposalId)
        
        if (updateError) {
          console.error('Error updating token:', updateError)
          return null
        }
        
        return newToken
      }
    } catch (err) {
      console.error('Error in fetchProposalToken:', err)
      return null
    }
  }

  const handleSendClick = async () => {
    // Validate we have required data
    if (!proposalId) {
      alert('Error: Proposal ID is missing. Please refresh the page and try again.')
      return
    }

    if (!customerEmail && !emailTo) {
      alert('Customer email is required')
      return
    }

    const token = await fetchProposalToken()
    if (!token) {
      alert('Error generating proposal link. Please try again.')
      return
    }
    
    setProposalToken(token)
    
    const baseUrl = window.location.origin
    const viewLink = `${baseUrl}/proposal/view/${token}`
    
    const defaultMessage = `Dear ${customerName || 'Customer'},

We're pleased to present you with Proposal #${proposalNumber} for your HVAC service needs.

Please review the attached proposal and let us know if you have any questions.

You can view and approve your proposal by clicking the link below:
${viewLink}

Best regards,
Your HVAC Team`

    setEmailContent(defaultMessage)
    setShowModal(true)
  }

  const handleSend = async () => {
    // Final validation before sending
    if (!proposalId) {
      alert('Error: Proposal ID is missing')
      return
    }

    if (!emailTo || !emailContent) {
      alert('Please fill in all required fields')
      return
    }

    setIsLoading(true)
    
    try {
      const baseUrl = window.location.origin
      const proposalUrl = `${baseUrl}/proposal/view/${proposalToken}`
      
      console.log('Sending email with:', {
        proposalId,
        proposalNumber,
        to: emailTo,
        customerName
      })
      
      // Send email using Resend API
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: proposalId,  // Explicitly include proposalId
          to: emailTo,
          subject: `Proposal ${proposalNumber} from Service Pro`,
          message: emailContent,
          customer_name: customerName || 'Customer',
          proposal_number: proposalNumber,
          proposal_url: proposalUrl,
          send_copy: sendCopy
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to send email')
      }

      // Update proposal status
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

  const renderButton = () => {
    if (variant === 'icon') {
      return (
        <button
          onClick={handleSendClick}
          className="text-green-600 hover:text-green-800"
          title="Send Proposal"
        >
          <PaperAirplaneIcon className="h-5 w-5" />
        </button>
      )
    }

    if (variant === 'button') {
      return (
        <button
          onClick={handleSendClick}
          className="flex-1 text-center px-3 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
          disabled={!proposalId}
        >
          {buttonText}
        </button>
      )
    }

    // Full button with icon
    return (
      <button
        onClick={handleSendClick}
        className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
        disabled={!proposalId}
      >
        <PaperAirplaneIcon className="h-4 w-4 mr-2" />
        {buttonText}
      </button>
    )
  }

  // Debug log to check props
  useEffect(() => {
    console.log('SendProposal props:', {
      proposalId,
      proposalNumber,
      customerEmail,
      customerName
    })
  }, [proposalId, proposalNumber, customerEmail, customerName])

  return (
    <>
      {renderButton()}

      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4 max-h-[80vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold">Send Proposal #{proposalNumber}</h3>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-500 hover:text-gray-700 text-2xl leading-none"
              >
                ×
              </button>
            </div>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                To:
              </label>
              <input
                type="email"
                value={emailTo}
                onChange={(e) => setEmailTo(e.target.value)}
                className="w-full p-2 border rounded-md"
                placeholder="customer@email.com"
                required
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Subject:
              </label>
              <div className="p-2 bg-gray-50 rounded">
                Proposal {proposalNumber} from Service Pro
              </div>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Message:
              </label>
              <textarea
                value={emailContent}
                onChange={(e) => setEmailContent(e.target.value)}
                className="w-full p-2 border rounded-md font-mono text-sm"
                rows={12}
                required
              />
            </div>

            <div className="mb-4">
              <label className="flex items-center">
                <input
                  type="checkbox"
                  checked={sendCopy}
                  onChange={(e) => setSendCopy(e.target.checked)}
                  className="mr-2"
                />
                <span className="text-sm text-gray-700">Send a copy to business email</span>
              </label>
            </div>

            {/* Debug info - remove in production */}
            <div className="text-xs text-gray-400 mb-2">
              Debug: Proposal ID: {proposalId || 'MISSING'}
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
                disabled={isLoading || !emailTo || !emailContent || !proposalId}
              >
                {isLoading ? 'Sending...' : 'Send Email'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
