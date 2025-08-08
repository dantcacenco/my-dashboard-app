'use client';

import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Send } from 'lucide-react';
import { toast } from 'sonner';

interface SendProposalModalProps {
  proposal: {
    id: string;
    proposal_number: string;
    total: number;
    customers?: {
      name: string;
      email: string;
    };
  };
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSent?: () => void;
}

export default function SendProposalModal({ proposal, open, onOpenChange, onSent }: SendProposalModalProps) {
  const [sending, setSending] = useState(false);
  const [email, setEmail] = useState(proposal.customers?.email || '');
  const [message, setMessage] = useState(
    `Hi ${proposal.customers?.name || 'there'},\n\nPlease find attached your service proposal #${proposal.proposal_number}.\n\nThe total amount is $${proposal.total.toFixed(2)}.\n\nYou can review and approve the proposal by clicking the link below.\n\nThank you for your business!`
  );

  const handleSend = async () => {
    if (!email) {
      toast.error('Please enter an email address');
      return;
    }

    setSending(true);
    try {
      const response = await fetch('/api/send-proposal', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: proposal.id,
          email,
          message
        })
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to send proposal');
      }

      toast.success('Proposal sent successfully!');
      onOpenChange(false);
      onSent?.();
    } catch (error: any) {
      console.error('Error sending proposal:', error);
      toast.error(error.message || 'Failed to send proposal');
    } finally {
      setSending(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[525px]">
        <DialogHeader>
          <DialogTitle>Send Proposal #{proposal.proposal_number}</DialogTitle>
          <DialogDescription>
            Send this proposal to your customer via email
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid gap-2">
            <Label htmlFor="email">Email Address</Label>
            <Input
              id="email"
              type="email"
              value={email}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEmail(e.target.value)}
              placeholder="customer@example.com"
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="message">Message</Label>
            <Textarea
              id="message"
              value={message}
              onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setMessage(e.target.value)}
              rows={8}
              placeholder="Enter your message..."
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={sending}>
            Cancel
          </Button>
          <Button onClick={handleSend} disabled={sending || !email} className="bg-green-600 hover:bg-green-700">
            <Send className="mr-2 h-4 w-4" />
            {sending ? 'Sending...' : 'Send Proposal'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
