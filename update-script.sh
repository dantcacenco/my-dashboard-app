#!/bin/bash

# Fix missing proposal ID error in send email

set -e

echo "🔧 Fixing missing proposal ID error..."

# Fix SendProposal component to ensure proposalId is passed correctly
echo "📝 Fixing SendProposal component..."
cat > components/SendProposal.tsx << 'EOF'
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
EOF

# Fix the send-proposal API to handle the proposalId properly
echo "📝 Updating send-proposal API..."
cat > app/api/send-proposal/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server'
import { Resend } from 'resend'
import { createClient } from '@/lib/supabase/server'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    console.log('Received request body:', body)
    
    const {
      proposalId,  // This is the proposal ID
      to,
      subject,
      message,
      customer_name,
      proposal_number,
      proposal_url,
      send_copy
    } = body

    // Validate required fields
    if (!proposalId) {
      console.error('Missing proposalId in request')
      return NextResponse.json(
        { error: 'Missing proposal ID' },
        { status: 400 }
      )
    }

    if (!to || !subject || !message) {
      console.error('Missing required email fields')
      return NextResponse.json(
        { error: 'Missing required email fields' },
        { status: 400 }
      )
    }

    // Update proposal status first
    const supabase = await createClient()
    const { error: updateError } = await supabase
      .from('proposals')
      .update({ 
        status: 'sent',
        sent_at: new Date().toISOString()
      })
      .eq('id', proposalId)

    if (updateError) {
      console.error('Error updating proposal:', updateError)
    }

    // Get sender email config
    const fromEmail = process.env.EMAIL_FROM || 'onboarding@resend.dev'
    const businessEmail = process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com'

    // Create HTML email template
    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>${subject}</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #2563eb; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { padding: 20px; background: #f9fafb; border: 1px solid #e5e7eb; }
            .button { 
              display: inline-block; 
              padding: 12px 24px; 
              background: #2563eb; 
              color: white !important; 
              text-decoration: none; 
              border-radius: 6px; 
              margin: 20px 0; 
            }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; background: #f3f4f6; border-radius: 0 0 8px 8px; }
            .proposal-details { 
              background: white; 
              padding: 15px; 
              border-radius: 6px; 
              margin: 15px 0; 
              border: 1px solid #e5e7eb;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Service Pro HVAC</h1>
              <p>Professional HVAC Services</p>
            </div>
            
            <div class="content">
              <h2>Your Proposal is Ready for Review</h2>
              
              <div class="proposal-details">
                <h3>Proposal Details:</h3>
                <p><strong>Proposal Number:</strong> ${proposal_number}</p>
                <p><strong>Customer:</strong> ${customer_name}</p>
              </div>
              
              <div style="white-space: pre-line; margin: 20px 0;">
                ${message.replace(/\n/g, '<br>')}
              </div>
              
              <div style="text-align: center; margin: 30px 0;">
                <a href="${proposal_url}" class="button" style="color: white !important;">
                  View & Approve Proposal
                </a>
              </div>
              
              <p style="font-size: 14px; color: #666; text-align: center;">
                This link is secure and personalized for you.
              </p>
            </div>
            
            <div class="footer">
              <p><strong>Service Pro HVAC</strong></p>
              <p>Phone: (555) 123-4567 | Email: info@servicepro.com</p>
              <p>Professional HVAC Services</p>
            </div>
          </div>
        </body>
      </html>
    `

    // Send email to customer
    console.log('Sending email to:', to)
    const emailResult = await resend.emails.send({
      from: `Service Pro <${fromEmail}>`,
      to: [to],
      subject: subject,
      html: htmlContent,
      text: message + `\n\nView your proposal: ${proposal_url}`
    })

    console.log('Email sent successfully:', emailResult)

    // Send copy to business email if requested
    if (send_copy) {
      console.log('Sending copy to business:', businessEmail)
      await resend.emails.send({
        from: `Service Pro <${fromEmail}>`,
        to: [businessEmail],
        subject: `[COPY] ${subject}`,
        html: `
          <div style="background: #fef3c7; padding: 10px; margin-bottom: 20px; border-radius: 4px;">
            <strong>This is a copy of the proposal sent to ${customer_name} (${to})</strong>
          </div>
          ${htmlContent}
        `,
        text: `[COPY] Sent to ${customer_name} (${to})\n\n${message}\n\nView proposal: ${proposal_url}`
      })
    }

    return NextResponse.json({ 
      success: true, 
      emailId: emailResult.data?.id,
      message: 'Email sent successfully'
    })

  } catch (error: any) {
    console.error('Error in send-proposal API:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to send email' },
      { status: 500 }
    )
  }
}
EOF

# Commit and push
echo "🚀 Committing and pushing fixes..."
git add -A
git commit -m "Fix missing proposal ID error in email sending

- Added proper proposalId validation and passing
- Added debug logging to track proposal ID
- Improved error messages for missing data
- Fixed API to properly handle proposalId parameter
- Added validation checks before sending" || echo "No changes"

git push origin main

echo ""
echo "✅ Fix applied and pushed!"
echo ""
echo "📋 What was fixed:"
echo "1. ✅ ProposalId now properly passed to API"
echo "2. ✅ Added validation for missing proposal ID"
echo "3. ✅ Better error messages"
echo "4. ✅ Debug logging to track issues"
echo "5. ✅ Email should now send successfully"
echo ""
echo "🧪 To test:"
echo "1. Go to a proposal view page"
echo "2. Click Send Proposal"
echo "3. Check the debug info shows proposal ID"
echo "4. Send the email - should work now!"
echo ""
echo "Note: The debug info at bottom of modal shows the proposal ID"
echo "Remove this in production once confirmed working."