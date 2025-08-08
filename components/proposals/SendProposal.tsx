'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Send, Loader2, X } from 'lucide-react'
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'

export interface SendProposalProps {
  proposalId: string
  proposalNumber: string
  customerEmail: string
  customerName?: string
  currentToken: string | null
  onSent?: (proposalId: string, token: string) => void
  buttonVariant?: 'default' | 'outline' | 'ghost'
  buttonSize?: 'default' | 'sm' | 'lg'
  buttonClassName?: string
  buttonText?: string
  showIcon?: boolean
}

export default function SendProposal({
  proposalId,
  proposalNumber,
  customerEmail,
  customerName = 'Customer',
  currentToken,
  onSent,
  buttonVariant = 'outline',
  buttonSize = 'sm',
  buttonClassName = '',
  buttonText = 'Send',
  showIcon = true
}: SendProposalProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [isSending, setIsSending] = useState(false)
  const [emailContent, setEmailContent] = useState('')

  // Initialize email content when modal opens
  const handleOpen = () => {
    const proposalLink = `${window.location.origin}/proposal/view/${currentToken || 'generating...'}`
    const defaultContent = `Dear ${customerName},

Please find attached your proposal #${proposalNumber}.

You can view and approve your proposal by clicking the link below:
${proposalLink}

If you have any questions, please don't hesitate to contact us.

Best regards,
Your HVAC Team`
    
    setEmailContent(defaultContent)
    setIsOpen(true)
  }

  const handleSend = async () => {
    setIsSending(true)
    
    try {
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          proposalId,
          email: customerEmail,
          emailContent,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to send proposal')
      }

      // Success
      setIsOpen(false)
      if (onSent) {
        onSent(proposalId, data.token)
      }
      // Show success message (you can add a toast here if you have one)
      alert('Proposal sent successfully!')
      
    } catch (error: any) {
      console.error('Error sending proposal:', error)
      alert('Failed to send proposal: ' + (error.message || 'Unknown error'))
    } finally {
      setIsSending(false)
    }
  }

  return (
    <>
      <Button 
        variant={buttonVariant as any}
        size={buttonSize as any}
        className={buttonClassName}
        onClick={handleOpen}
      >
        {showIcon && <Send className="h-4 w-4 mr-1" />}
        {buttonText}
      </Button>

      {/* Email Preview Modal */}
      {isOpen && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <Card className="w-full max-w-2xl">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>Send Proposal #{proposalNumber}</CardTitle>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setIsOpen(false)}
                disabled={isSending}
              >
                <X className="h-4 w-4" />
              </Button>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium text-muted-foreground">To:</label>
                <div className="mt-1 font-medium">{customerEmail}</div>
              </div>
              <div>
                <label className="text-sm font-medium text-muted-foreground">Subject:</label>
                <div className="mt-1 font-medium">Your Proposal #{proposalNumber} is Ready</div>
              </div>
              <div>
                <label className="text-sm font-medium text-muted-foreground">Message:</label>
                <textarea
                  className="mt-1 w-full min-h-[250px] p-3 rounded-md border bg-background resize-none focus:outline-none focus:ring-2 focus:ring-ring"
                  value={emailContent}
                  onChange={(e) => setEmailContent(e.target.value)}
                  disabled={isSending}
                  placeholder="Enter your message..."
                />
              </div>
            </CardContent>
            <CardFooter className="flex justify-end gap-2">
              <Button
                variant="outline"
                onClick={() => setIsOpen(false)}
                disabled={isSending}
              >
                Cancel
              </Button>
              <Button
                onClick={handleSend}
                disabled={isSending || !emailContent.trim()}
              >
                {isSending ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Sending...
                  </>
                ) : (
                  <>
                    <Send className="mr-2 h-4 w-4" />
                    Send Email
                  </>
                )}
              </Button>
            </CardFooter>
          </Card>
        </div>
      )}
    </>
  )
}
