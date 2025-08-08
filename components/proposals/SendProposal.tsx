'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Send, Loader2 } from 'lucide-react'

export interface SendProposalProps {
  proposalId: string
  proposalNumber: string
  customerEmail: string
  currentToken: string | null
  onSent: (proposalId: string, token: string) => void
}

export default function SendProposal({
  proposalId,
  proposalNumber,
  customerEmail,
  currentToken,
  onSent
}: SendProposalProps) {
  const [isSending, setIsSending] = useState(false)

  const handleSend = async () => {
    // For now, just use window.confirm as a simple solution
    const email = window.prompt('Enter customer email:', customerEmail || '')
    
    if (!email) {
      return
    }

    setIsSending(true)
    
    try {
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId,
          email,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to send proposal')
      }

      alert('Proposal sent successfully!')
      onSent(proposalId, data.token)
      
    } catch (error: any) {
      console.error('Error sending proposal:', error)
      alert('Failed to send proposal: ' + (error.message || 'Unknown error'))
    } finally {
      setIsSending(false)
    }
  }

  return (
    <Button 
      variant="outline" 
      size="sm" 
      className="flex-1"
      onClick={handleSend}
      disabled={isSending}
    >
      {isSending ? (
        <>
          <Loader2 className="h-4 w-4 mr-1 animate-spin" />
          Sending...
        </>
      ) : (
        <>
          <Send className="h-4 w-4 mr-1" />
          Send
        </>
      )}
    </Button>
  )
}
