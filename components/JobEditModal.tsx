'use client'

import { useState, useEffect } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Badge } from '@/components/ui/badge'
import { MapPin, Phone, Mail, Calendar, DollarSign, Users } from 'lucide-react'
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import { getUnifiedDisplayStatus } from '@/lib/status-sync'

interface JobEditModalProps {
  job: any
  isOpen: boolean
  onClose: () => void
  onUpdate?: () => void
}

export default function JobEditModal({ job, isOpen, onClose, onUpdate }: JobEditModalProps) {
  const [editedJob, setEditedJob] = useState(job)
  const [isSaving, setIsSaving] = useState(false)
  const supabase = createClientComponentClient()

  useEffect(() => {
    setEditedJob(job)
  }, [job])

  const handleSave = async () => {
    setIsSaving(true)
    try {
      // Prepare job update data
      const jobUpdateData: any = {
        title: editedJob.title,
        description: editedJob.description,
        scheduled_date: editedJob.scheduled_date,
        scheduled_time: editedJob.scheduled_time
      }

      // Only update job status if there's no proposal
      if (!editedJob.proposals) {
        jobUpdateData.status = editedJob.status
      }

      // Update job details
      const { error: jobError } = await supabase
        .from('jobs')
        .update(jobUpdateData)
        .eq('id', editedJob.id)

      if (jobError) throw jobError

      // If there's a proposal, update its status (DB triggers will sync to job)
      if (editedJob.proposals && editedJob.proposals.id) {
        const { error: proposalError } = await supabase
          .from('proposals')
          .update({
            status: editedJob.proposals.status
          })
          .eq('id', editedJob.proposals.id)

        if (proposalError) throw proposalError
      }

      if (onUpdate) onUpdate()
      onClose()
    } catch (error) {
      console.error('Error updating job:', error)
    } finally {
      setIsSaving(false)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    if (!dateString) return 'Not scheduled'
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const getStatusColor = (status: string) => {
    const normalizedStatus = status.toLowerCase().replace(' ', '_').replace('-', '_')
    
    switch (normalizedStatus) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'approved': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      case 'deposit_paid': return 'bg-blue-100 text-blue-800'
      case 'rough_in_paid': return 'bg-yellow-100 text-yellow-800'
      case 'final_payment_complete': return 'bg-green-100 text-green-800'
      case 'final_paid': return 'bg-green-100 text-green-800'
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'scheduled': return 'bg-blue-100 text-blue-800'
      case 'in_progress': return 'bg-purple-100 text-purple-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      case 'not_scheduled': return 'bg-gray-100 text-gray-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  if (!job) return null

  const displayStatus = getUnifiedDisplayStatus(job.status, job.proposals?.status)

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Job {job.job_number}</DialogTitle>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Status Badge */}
          <div>
            <Badge className={getStatusColor(displayStatus)}>
              {displayStatus}
            </Badge>
          </div>

          {/* Customer Info */}
          {job.customers && (
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold mb-2">Customer Information</h3>
              <div className="space-y-1 text-sm">
                <p className="font-medium">{job.customers.name}</p>
                {job.customers.email && (
                  <p className="flex items-center gap-1">
                    <Mail className="h-3 w-3" />
                    {job.customers.email}
                  </p>
                )}
                {job.customers.phone && (
                  <p className="flex items-center gap-1">
                    <Phone className="h-3 w-3" />
                    {job.customers.phone}
                  </p>
                )}
                {job.customers.address && (
                  <p className="flex items-center gap-1">
                    <MapPin className="h-3 w-3" />
                    {job.customers.address}
                  </p>
                )}
              </div>
            </div>
          )}

          {/* Job Details */}
          <div className="space-y-3">
            <div>
              <Label htmlFor="title">Job Title</Label>
              <Input
                id="title"
                value={editedJob.title || ''}
                onChange={(e) => setEditedJob({ ...editedJob, title: e.target.value })}
              />
            </div>

            <div>
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={editedJob.description || ''}
                onChange={(e) => setEditedJob({ ...editedJob, description: e.target.value })}
                rows={3}
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label htmlFor="scheduled_date">Scheduled Date</Label>
                <Input
                  id="scheduled_date"
                  type="date"
                  value={editedJob.scheduled_date?.split('T')[0] || ''}
                  onChange={(e) => setEditedJob({ ...editedJob, scheduled_date: e.target.value })}
                />
              </div>

              <div>
                <Label htmlFor="scheduled_time">Scheduled Time</Label>
                <Input
                  id="scheduled_time"
                  type="time"
                  value={editedJob.scheduled_time || ''}
                  onChange={(e) => setEditedJob({ ...editedJob, scheduled_time: e.target.value })}
                />
              </div>
            </div>

            <div>
              <Label htmlFor="status">Status</Label>
              {editedJob.proposals ? (
                // If job has a proposal, use proposal statuses
                <select
                  id="status"
                  className="w-full px-3 py-2 border rounded-md"
                  value={editedJob.proposals.status}
                  onChange={(e) => setEditedJob({ 
                    ...editedJob, 
                    proposals: { ...editedJob.proposals, status: e.target.value }
                  })}
                >
                  <option value="draft">Draft</option>
                  <option value="sent">Sent</option>
                  <option value="approved">Approved</option>
                  <option value="rejected">Rejected</option>
                  <option value="deposit paid">Deposit Paid</option>
                  <option value="rough-in paid">Rough-In Paid</option>
                  <option value="final paid">Final Paid</option>
                  <option value="completed">Completed</option>
                </select>
              ) : (
                // If no proposal, use job statuses
                <select
                  id="status"
                  className="w-full px-3 py-2 border rounded-md"
                  value={editedJob.status}
                  onChange={(e) => setEditedJob({ ...editedJob, status: e.target.value })}
                >
                  <option value="not_scheduled">Not Scheduled</option>
                  <option value="scheduled">Scheduled</option>
                  <option value="in_progress">In Progress</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              )}
            </div>
          </div>

          {/* Financial Info - Only show if proposal exists */}
          {job.proposals && job.proposals.total && (
            <div className="bg-blue-50 p-4 rounded-lg">
              <h3 className="font-semibold mb-2">Financial Information</h3>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span className="text-gray-600">Total Amount:</span>
                  <p className="font-semibold">{formatCurrency(job.proposals.total)}</p>
                </div>
                {job.proposals.deposit_amount && (
                  <div>
                    <span className="text-gray-600">Deposit (50%):</span>
                    <p className="font-semibold">{formatCurrency(job.proposals.deposit_amount)}</p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Technicians */}
          {job.job_technicians && job.job_technicians.length > 0 && (
            <div>
              <h3 className="font-semibold mb-2">Assigned Technicians</h3>
              <div className="flex gap-2">
                {job.job_technicians.map((tech: any) => (
                  <Badge key={tech.id} variant="outline">
                    <Users className="h-3 w-3 mr-1" />
                    {tech.profiles?.full_name || 'Technician'}
                  </Badge>
                ))}
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex justify-between pt-4">
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <div className="flex gap-2">
              <Button asChild variant="outline">
                <a href={`/jobs/${job.id}`} target="_blank">
                  View Full Details
                </a>
              </Button>
              <Button onClick={handleSave} disabled={isSaving}>
                {isSaving ? 'Saving...' : 'Save Changes'}
              </Button>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
