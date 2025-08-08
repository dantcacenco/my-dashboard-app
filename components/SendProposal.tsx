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
  const supabase = createClient()

  useEffect(() => {
    setEmailTo(customerEmail || '')
  }, [customerEmail])

  const fetchProposalToken = async () => {
    const { data, error } = await supabase
      .from('proposals')
      .select('customer_view_token')
      .eq('id', proposalId)
      .single()

    if (data?.customer_view_token) {
      return data.customer_view_token
    } else {
      const newToken = crypto.randomUUID()
      await supabase
        .from('proposals')
        .update({ customer_view_token: newToken })
        .eq('id', proposalId)
      return newToken
    }
  }

  const handleSendClick = async () => {
    if (!customerEmail && !emailTo) {
      alert('Customer email is required')
      return
    }

    const token = await fetchProposalToken()
    setProposalToken(token)
    
    const baseUrl = window.location.origin
    const viewLink = `${baseUrl}/proposal/view/${token}`
    
    const defaultMessage = `Dear ${customerName || 'Customer'},

Please find attached your proposal #${proposalNumber}.

You can view and approve your proposal by clicking the link below:
${viewLink}

If you have any questions, please don't hesitate to contact us.

Best regards,
Your HVAC Team`

    setEmailContent(defaultMessage)
    setShowModal(true)
  }

  const handleSend = async () => {
    if (!emailTo || !emailContent || !proposalId || !proposalNumber) {
      alert('Please fill in all required fields')
      return
    }

    setIsLoading(true)
    
    try {
      // For now, we'll simulate sending since email service isn't configured
      // In production, you'd integrate with SendGrid, Resend, etc.
      console.log('Would send email to:', emailTo)
      console.log('Proposal link:', `${window.location.origin}/proposal/view/${proposalToken}`)
      
      // Update proposal status
      const { error: updateError } = await supabase
        .from('proposals')
        .update({ 
          status: 'sent',
          sent_at: new Date().toISOString()
        })
        .eq('id', proposalId)

      if (updateError) {
        throw updateError
      }

      alert('Proposal marked as sent! (Email service not configured - in production, email would be sent)')
      setShowModal(false)
      onSent?.()
    } catch (error: any) {
      console.error('Error:', error)
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
          disabled={!customerEmail}
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
          disabled={!customerEmail}
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
        disabled={!customerEmail}
      >
        <PaperAirplaneIcon className="h-4 w-4 mr-2" />
        {buttonText}
      </button>
    )
  }

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
              />
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
                className="w-full p-2 border rounded-md font-mono text-sm"
                rows={12}
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
                disabled={isLoading || !emailTo || !emailContent}
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
