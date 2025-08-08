'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Send, Loader2, CheckCircle } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'

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
  const [isOpen, setIsOpen] = useState(false)
  const [isSending, setIsSending] = useState(false)
  const [email, setEmail] = useState(customerEmail)
  const [wasSent, setWasSent] = useState(false)

  const handleSend = async () => {
    if (!email) {
      toast.error('Please enter an email address')
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

      toast.success('Proposal sent successfully!')
      setWasSent(true)
      onSent(proposalId, data.token)
      
      // Close dialog after a short delay
      setTimeout(() => {
        setIsOpen(false)
        setWasSent(false)
      }, 2000)
    } catch (error: any) {
      console.error('Error sending proposal:', error)
      toast.error(error.message || 'Failed to send proposal')
    } finally {
      setIsSending(false)
    }
  }

  const handleCopyLink = () => {
    if (currentToken) {
      const link = `${window.location.origin}/proposal/view/${currentToken}`
      navigator.clipboard.writeText(link)
      toast.success('Link copied to clipboard!')
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm" className="flex-1">
          <Send className="h-4 w-4 mr-1" />
          Send
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Send Proposal #{proposalNumber}</DialogTitle>
          <DialogDescription>
            Send this proposal to the customer via email or copy the link.
          </DialogDescription>
        </DialogHeader>
        
        {wasSent ? (
          <div className="flex flex-col items-center justify-center py-8">
            <CheckCircle className="h-12 w-12 text-green-500 mb-4" />
            <p className="text-lg font-medium">Proposal Sent!</p>
            <p className="text-sm text-muted-foreground mt-2">
              The customer will receive an email with the proposal link.
            </p>
          </div>
        ) : (
          <>
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="email" className="text-right">
                  Email
                </Label>
                <Input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="col-span-3"
                  placeholder="customer@example.com"
                />
              </div>
              
              {currentToken && (
                <div className="text-sm text-muted-foreground">
                  <p className="mb-2">Or copy the direct link:</p>
                  <div className="flex gap-2">
                    <Input
                      readOnly
                      value={`${window.location.origin}/proposal/view/${currentToken}`}
                      className="text-xs"
                    />
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={handleCopyLink}
                    >
                      Copy
                    </Button>
                  </div>
                </div>
              )}
            </div>
            
            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsOpen(false)}
                disabled={isSending}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                onClick={handleSend}
                disabled={isSending || !email}
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
            </DialogFooter>
          </>
        )}
      </DialogContent>
    </Dialog>
  )
}
