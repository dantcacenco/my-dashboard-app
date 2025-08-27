'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Calendar, Clock, MapPin, User, Phone, Mail, DollarSign, Edit, X, Save } from 'lucide-react'
import { toast } from 'sonner'

interface JobDetailModalProps {
  jobId: string
  isOpen: boolean
  onClose: () => void
  onUpdate?: () => void
}

export default function JobDetailModal({ jobId, isOpen, onClose, onUpdate }: JobDetailModalProps) {
  const [job, setJob] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [isEditing, setIsEditing] = useState(false)
  const [editedJob, setEditedJob] = useState<any>(null)
  const [technicians, setTechnicians] = useState<any[]>([])
  const supabase = createClient()

  useEffect(() => {
    if (isOpen && jobId) {
      loadJob()
      loadTechnicians()
    }
  }, [isOpen, jobId])

  const loadJob = async () => {
    setLoading(true)
    const { data, error } = await supabase
      .from('jobs')
      .select(`
        *,
        customers (name, email, phone, address),
        profiles!jobs_technician_id_fkey (full_name, email)
      `)
      .eq('id', jobId)
      .single()

    if (error) {
      console.error('Error loading job:', error)
      toast.error('Failed to load job details')
    } else {
      setJob(data)
      setEditedJob(data)
    }
    setLoading(false)
  }

  const loadTechnicians = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
    
    setTechnicians(data || [])
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'draft': 'bg-gray-500',
      'sent': 'bg-blue-500',
      'viewed': 'bg-purple-500',
      'approved': 'bg-green-500',
      'rejected': 'bg-red-500',
      'not_scheduled': 'bg-gray-500',
      'scheduled': 'bg-blue-500',
      'in_progress': 'bg-yellow-500',
      'completed': 'bg-green-500',
      'cancelled': 'bg-red-500'
    }
    return colors[status] || 'bg-gray-500'
  }

  const getStatusLabel = (status: string) => {
    return status.replace(/_/g, ' ').toUpperCase()
  }

  const handleSave = async () => {
    try {
      const { error } = await supabase
        .from('jobs')
        .update({
          title: editedJob.title,
          description: editedJob.description,
          job_type: editedJob.job_type,
          status: editedJob.status,
          technician_id: editedJob.technician_id,
          scheduled_date: editedJob.scheduled_date,
          scheduled_time: editedJob.scheduled_time,
          notes: editedJob.notes
        })
        .eq('id', jobId)

      if (error) throw error

      toast.success('Job updated successfully')
      setJob(editedJob)
      setIsEditing(false)
      if (onUpdate) onUpdate()
    } catch (error) {
      console.error('Error updating job:', error)
      toast.error('Failed to update job')
    }
  }

  if (loading) {
    return (
      <Dialog open={isOpen} onOpenChange={onClose}>
        <DialogContent className="max-w-3xl">
          <div className="flex items-center justify-center p-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          </div>
        </DialogContent>
      </Dialog>
    )
  }

  if (!job) return null

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <DialogTitle className="text-xl font-bold">
              Job {job.job_number}
            </DialogTitle>
            <div className="flex items-center gap-2">
              <Badge className={`${getStatusColor(job.status)} text-white`}>
                {getStatusLabel(job.status)}
              </Badge>
              {!isEditing ? (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setIsEditing(true)}
                >
                  <Edit className="h-4 w-4 mr-1" />
                  Edit
                </Button>
              ) : (
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      setEditedJob(job)
                      setIsEditing(false)
                    }}
                  >
                    <X className="h-4 w-4 mr-1" />
                    Cancel
                  </Button>
                  <Button
                    size="sm"
                    onClick={handleSave}
                  >
                    <Save className="h-4 w-4 mr-1" />
                    Save
                  </Button>
                </div>
              )}
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-6 mt-4">
          {/* Job Title & Type */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Job Title</Label>
              {isEditing ? (
                <Input
                  value={editedJob.title}
                  onChange={(e) => setEditedJob({...editedJob, title: e.target.value})}
                />
              ) : (
                <p className="font-medium">{job.title}</p>
              )}
            </div>
            <div>
              <Label>Job Type</Label>
              {isEditing ? (
                <Select
                  value={editedJob.job_type}
                  onValueChange={(value) => setEditedJob({...editedJob, job_type: value})}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="installation">Installation</SelectItem>
                    <SelectItem value="maintenance">Maintenance</SelectItem>
                    <SelectItem value="repair">Repair</SelectItem>
                    <SelectItem value="inspection">Inspection</SelectItem>
                  </SelectContent>
                </Select>
              ) : (
                <p className="font-medium capitalize">{job.job_type}</p>
              )}
            </div>
          </div>

          {/* Customer Info */}
          <div>
            <Label>Customer</Label>
            <div className="bg-gray-50 p-3 rounded-lg space-y-1">
              <p className="font-medium">{job.customers?.name}</p>
              {job.customers?.phone && (
                <p className="text-sm text-muted-foreground flex items-center gap-1">
                  <Phone className="h-3 w-3" />
                  {job.customers.phone}
                </p>
              )}
              {job.customers?.email && (
                <p className="text-sm text-muted-foreground flex items-center gap-1">
                  <Mail className="h-3 w-3" />
                  {job.customers.email}
                </p>
              )}
              {job.customers?.address && (
                <p className="text-sm text-muted-foreground flex items-center gap-1">
                  <MapPin className="h-3 w-3" />
                  {job.customers.address}
                </p>
              )}
            </div>
          </div>

          {/* Scheduling */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Scheduled Date</Label>
              {isEditing ? (
                <Input
                  type="date"
                  value={editedJob.scheduled_date || ''}
                  onChange={(e) => setEditedJob({...editedJob, scheduled_date: e.target.value})}
                />
              ) : (
                <p className="font-medium flex items-center gap-1">
                  <Calendar className="h-4 w-4" />
                  {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : 'Not scheduled'}
                </p>
              )}
            </div>
            <div>
              <Label>Scheduled Time</Label>
              {isEditing ? (
                <Input
                  type="time"
                  value={editedJob.scheduled_time || ''}
                  onChange={(e) => setEditedJob({...editedJob, scheduled_time: e.target.value})}
                />
              ) : (
                <p className="font-medium flex items-center gap-1">
                  <Clock className="h-4 w-4" />
                  {job.scheduled_time || 'Not set'}
                </p>
              )}
            </div>
          </div>

          {/* Status & Technician */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Status</Label>
              {isEditing ? (
                <Select
                  value={editedJob.status}
                  onValueChange={(value) => setEditedJob({...editedJob, status: value})}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="not_scheduled">Not Scheduled</SelectItem>
                    <SelectItem value="scheduled">Scheduled</SelectItem>
                    <SelectItem value="in_progress">In Progress</SelectItem>
                    <SelectItem value="completed">Completed</SelectItem>
                    <SelectItem value="cancelled">Cancelled</SelectItem>
                  </SelectContent>
                </Select>
              ) : (
                <Badge className={`${getStatusColor(job.status)} text-white`}>
                  {getStatusLabel(job.status)}
                </Badge>
              )}
            </div>
            <div>
              <Label>Assigned Technician</Label>
              {isEditing ? (
                <Select
                  value={editedJob.technician_id || ''}
                  onValueChange={(value) => setEditedJob({...editedJob, technician_id: value})}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select technician" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">Unassigned</SelectItem>
                    {technicians.map((tech) => (
                      <SelectItem key={tech.id} value={tech.id}>
                        {tech.full_name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              ) : (
                <p className="font-medium flex items-center gap-1">
                  <User className="h-4 w-4" />
                  {job.profiles?.full_name || 'Unassigned'}
                </p>
              )}
            </div>
          </div>

          {/* Description */}
          <div>
            <Label>Description</Label>
            {isEditing ? (
              <Textarea
                value={editedJob.description || ''}
                onChange={(e) => setEditedJob({...editedJob, description: e.target.value})}
                rows={3}
              />
            ) : (
              <p className="text-sm text-muted-foreground">
                {job.description || 'No description provided'}
              </p>
            )}
          </div>

          {/* Notes */}
          <div>
            <Label>Notes</Label>
            {isEditing ? (
              <Textarea
                value={editedJob.notes || ''}
                onChange={(e) => setEditedJob({...editedJob, notes: e.target.value})}
                rows={3}
                placeholder="Add notes..."
              />
            ) : (
              <div className="bg-gray-50 p-3 rounded-lg">
                <p className="text-sm whitespace-pre-wrap">
                  {job.notes || 'No notes'}
                </p>
              </div>
            )}
          </div>

          {/* Financial Info */}
          <div>
            <Label>Total Amount</Label>
            <p className="font-medium text-lg flex items-center gap-1">
              <DollarSign className="h-4 w-4" />
              {job.total_amount ? `$${job.total_amount.toFixed(2)}` : 'N/A'}
            </p>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
