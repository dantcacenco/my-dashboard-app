'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

interface Customer {
  id: string
  name: string
  email: string
  phone: string
  address: string
}

interface SendProposalProps {
  proposalId: string
  proposalNumber: string
  customer: Customer
  total: number
  onSent: () => void
  onCancel: () => void
}

export default function SendProposal({ 
  proposalId, 
  proposalNumber, 
  customer, 
  total, 
  onSent, 
  onCancel 
}: SendProposalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [emailSubject, setEmailSubject] = useState(
    `Proposal ${proposalNumber} from Service Pro`
  )
  const [emailMessage, setEmailMessage] = useState(
    `Dear ${customer.name},

Please find attached your proposal for HVAC services. This proposal includes detailed pricing and service descriptions.

Proposal Number: ${proposalNumber}
Total Amount: $${total.toFixed(2)}

You can review and approve this proposal by clicking the link below. If you have any questions, please don't hesitate to contact us.

Best regards,
Service Pro Team

Phone: (555) 123-4567
Email: info@servicepro.com`
  )
  const [sendCopy, setSendCopy] = useState(true)
  const [error, setError] = useState('')

  const supabase = createClient()

  const handleSend = async () => {
    if (!emailSubject.trim() || !emailMessage.trim()) {
      setError('Please fill in both subject and message')
      return
    }

    setIsLoading(true)
    setError('')

    try {
      // Create unique proposal view link for customer
      const viewToken = crypto.randomUUID()
      
      // Update proposal with view token and set status to 'sent'
      const { error: updateError } = await supabase
        .from('proposals')
        .update({
          status: 'sent',
          customer_view_token: viewToken,
          sent_at: new Date().toISOString()
        })
        .eq('id', proposalId)

      if (updateError) throw updateError

      // Create the customer view URL
      const customerViewUrl = `${window.location.origin}/proposal/view/${viewToken}`

      // Prepare email data
      const emailData = {
        to: customer.email,
        subject: emailSubject,
        message: emailMessage.replace(
          'by clicking the link below',
          `by clicking this link: ${customerViewUrl}`
        ),
        customer_name: customer.name,
        proposal_number: proposalNumber,
        proposal_url: customerViewUrl,
        send_copy: sendCopy
      }

      // Send email via API route
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(emailData)
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to send email')
      }

      // Log the email activity
      await supabase
        .from('proposal_activities')
        .insert({
          proposal_id: proposalId,
          activity_type: 'email_sent',
          description: `Proposal sent to ${customer.email}`,
          metadata: {
            email_subject: emailSubject,
            customer_email: customer.email,
            view_url: customerViewUrl
          }
        })

      onSent()
      
    } catch (error) {
      console.error('Error sending proposal:', error)
      setError(error instanceof Error ? error.message : 'Failed to send proposal')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-full max-w-2xl shadow-lg rounded-md bg-white">
        <div className="mt-3">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-medium text-gray-900">
              Send Proposal to Customer
            </h3>
            <button
              onClick={onCancel}
              className="text-gray-400 hover:text-gray-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {/* Customer Info */}
          <div className="bg-gray-50 rounded-lg p-4 mb-6">
            <h4 className="font-medium text-gray-900 mb-2">Sending to:</h4>
            <div className="text-sm text-gray-600">
              <p className="font-medium">{customer.name}</p>
              <p>{customer.email}</p>
              <p>{customer.phone}</p>
            </div>
          </div>

          {/* Email Form */}
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email Subject *
              </label>
              <input
                type="text"
                value={emailSubject}
                onChange={(e) => setEmailSubject(e.target.value)}
                className="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="Enter email subject"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email Message *
              </label>
              <textarea
                value={emailMessage}
                onChange={(e) => setEmailMessage(e.target.value)}
                rows={12}
                className="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="Enter your message to the customer"
              />
              <p className="text-xs text-gray-500 mt-1">
                A secure link to view and approve the proposal will be automatically included.
              </p>
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                id="sendCopy"
                checked={sendCopy}
                onChange={(e) => setSendCopy(e.target.checked)}
                className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              />
              <label htmlFor="sendCopy" className="ml-2 text-sm text-gray-700">
                Send a copy to myself
              </label>
            </div>
          </div>

          {/* Error Message */}
          {error && (
            <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          {/* Preview Info */}
          <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-md">
            <h4 className="font-medium text-blue-900 mb-2">What happens next?</h4>
            <ul className="text-sm text-blue-800 space-y-1">
              <li>• Customer receives email with secure proposal link</li>
              <li>• They can view, download, and approve the proposal online</li>
              <li>• You'll get notified when they view or approve it</li>
              <li>• Proposal status will be updated automatically</li>
            </ul>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3 mt-6">
            <button
              onClick={handleSend}
              disabled={isLoading}
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <div className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Sending...
                </div>
              ) : (
                'Send Proposal'
              )}
            </button>
            <button
              onClick={onCancel}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}