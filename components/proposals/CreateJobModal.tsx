'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'

interface CreateJobModalProps {
  isOpen: boolean
  onClose: () => void
  proposal: any
}

export default function CreateJobModal({ isOpen, onClose, proposal }: CreateJobModalProps) {
  const router = useRouter()
  const supabase = createClient()
  const [isCreating, setIsCreating] = useState(false)
  
  // Initialize form with proposal data
  // Use the proposal title or description, not a generic "Job from Proposal" text
  const proposalTitle = proposal.items?.find((item: any) => item.is_service)?.name || 
                       proposal.description || 
                       `${proposal.job_type || 'Service'} Job`
  
  const [formData, setFormData] = useState({
    title: proposalTitle, // Use actual proposal title/service name
    job_type: proposal.job_type || 'installation',
    status: 'not_scheduled',
    total_amount: proposal.total || 0,
    description: `SERVICES:\n${proposal.items?.filter((i: any) => i.is_service).map((i: any) => `${i.quantity}x ${i.name}`).join('\n') || ''}\n\nADD-ONS:\n${proposal.items?.filter((i: any) => !i.is_service).map((i: any) => `${i.quantity}x ${i.name}`).join('\n') || ''}`.trim(),
  })

  const handleCreate = async () => {
    setIsCreating(true)
    console.log('Creating job with title:', formData.title)
    
    try {
      // Generate job number
      const jobNumber = `JOB-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.random().toString(36).substr(2, 3).toUpperCase()}`

      // Create the job
      const { data: newJob, error } = await supabase
        .from('jobs')
        .insert({
          job_number: jobNumber,
          proposal_id: proposal.id,
          customer_id: proposal.customer_id,
          title: formData.title,
          description: formData.description,
          job_type: formData.job_type,
          status: formData.status,
          total_amount: formData.total_amount,
          payment_status: 'pending',
          created_by: proposal.created_by,
        })
        .select()
        .single()

      if (error) throw error

      toast.success('Job created successfully!')
      router.push(`/jobs/${newJob.id}`)
      onClose()
    } catch (error) {
      console.error('Error creating job:', error)
      toast.error('Failed to create job')
    } finally {
      setIsCreating(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Create Job from Proposal #{proposal.proposal_number}</DialogTitle>
          <p className="text-sm text-muted-foreground">
            Create a new job based on this approved proposal. The job details have been pre-filled.
          </p>
        </DialogHeader>
        
        <div className="space-y-4 py-4">
          <div>
            <Label>Customer</Label>
            <Input 
              value={`${proposal.customers?.name || 'Unknown'} - ${proposal.customers?.email || ''}`}
              disabled
            />
          </div>

          <div>
            <Label>Job Title *</Label>
            <Input
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="Enter job title..."
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Job Type</Label>
              <select
                className="w-full p-2 border rounded"
                value={formData.job_type}
                onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
              >
                <option value="installation">Installation</option>
                <option value="maintenance">Maintenance</option>
                <option value="repair">Repair</option>
                <option value="inspection">Inspection</option>
              </select>
            </div>

            <div>
              <Label>Status</Label>
              <select
                className="w-full p-2 border rounded"
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
              >
                <option value="not_scheduled">Not Scheduled</option>
                <option value="scheduled">Scheduled</option>
                <option value="in_progress">In Progress</option>
                <option value="completed">Completed</option>
              </select>
            </div>
          </div>

          <div>
            <Label>Total Value</Label>
            <Input
              type="number"
              value={formData.total_amount}
              onChange={(e) => setFormData({ ...formData, total_amount: parseFloat(e.target.value) || 0 })}
              step="0.01"
            />
          </div>

          <div>
            <Label>Description</Label>
            <Textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={6}
            />
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleCreate} disabled={isCreating || !formData.title}>
            {isCreating ? 'Creating...' : 'Create Job'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
