'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter
} from '@/components/ui/dialog'
import { 
  ArrowLeft, Calendar, Clock, MapPin, User, Phone, Mail,
  FileText, Camera, DollarSign, Edit, Trash2, UserPlus,
  Save, X
} from 'lucide-react'
import { toast } from 'sonner'
import MediaUpload from '@/components/uploads/MediaUpload'
import FileUpload from '@/components/uploads/FileUpload'

interface JobDetailsViewProps {
  job: any
  jobPhotos: any[]
  jobFiles: any[]
}

export default function JobDetailsView({ job: initialJob, jobPhotos: initialPhotos, jobFiles: initialFiles }: JobDetailsViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [job, setJob] = useState(initialJob)
  const [jobPhotos, setJobPhotos] = useState(initialPhotos)
  const [jobFiles, setJobFiles] = useState(initialFiles)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [editedJob, setEditedJob] = useState(job)
  const [isSaving, setIsSaving] = useState(false)
  const [technicians, setTechnicians] = useState<any[]>([])

  // Debug logging
  useEffect(() => {
    console.log('JobDetailsView mounted with:')
    console.log('- Job:', job)
    console.log('- Photos count:', jobPhotos.length)
    console.log('- Files count:', jobFiles.length)
    
    // Log photo URLs for debugging
    jobPhotos.forEach((photo, index) => {
      console.log(`Photo ${index + 1}:`)
      console.log('  - ID:', photo.id)
      console.log('  - URL:', photo.url)
      console.log('  - Type:', photo.media_type)
      console.log('  - Created:', photo.created_at)
      
      // Test if image loads
      if (photo.media_type === 'photo' || !photo.media_type) {
        const img = new Image()
        img.onload = () => console.log(`  ✅ Photo ${index + 1} loaded successfully`)
        img.onerror = (e) => console.error(`  ❌ Photo ${index + 1} failed to load:`, e)
        img.src = photo.url
      }
    })
  }, [job, jobPhotos, jobFiles])

  // Load technicians for assignment dropdown
  useEffect(() => {
    loadTechnicians()
  }, [])

  const loadTechnicians = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
    
    setTechnicians(data || [])
    console.log('Loaded technicians:', data?.length || 0)
  }

  const loadJobMedia = async () => {
    console.log('Reloading job media...')
    const { data } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: true })

    setJobPhotos(data || [])
    console.log('Reloaded photos:', data?.length || 0)
  }

  const loadJobFiles = async () => {
    console.log('Reloading job files...')
    const { data } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })

    setJobFiles(data || [])
    console.log('Reloaded files:', data?.length || 0)
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'not_scheduled': return 'bg-gray-500'
      case 'scheduled': return 'bg-blue-500'
      case 'in_progress': return 'bg-yellow-500'
      case 'completed': return 'bg-green-500'
      case 'cancelled': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  const handleEditClick = () => {
    console.log('Edit button clicked, opening modal with job:', job)
    setEditedJob({...job})
    setIsEditModalOpen(true)
  }

  const handleSaveChanges = async () => {
    console.log('Saving job changes:', editedJob)
    setIsSaving(true)
    
    try {
      const { error } = await supabase
        .from('jobs')
        .update({
          title: editedJob.title,
          description: editedJob.description,
          job_type: editedJob.job_type,
          status: editedJob.status,
          scheduled_date: editedJob.scheduled_date,
          scheduled_time: editedJob.scheduled_time,
          technician_id: editedJob.technician_id || null,
          address: editedJob.address,
          notes: editedJob.notes
        })
        .eq('id', job.id)

      if (error) throw error

      // Update local state
      setJob(editedJob)
      setIsEditModalOpen(false)
      toast.success('Job updated successfully')
      
      // Reload the page to get fresh data
      router.refresh()
    } catch (error) {
      console.error('Error updating job:', error)
      toast.error('Failed to update job')
    } finally {
      setIsSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this job?')) return

    try {
      const { error } = await supabase
        .from('jobs')
        .delete()
        .eq('id', job.id)

      if (error) throw error

      toast.success('Job deleted successfully')
      router.push('/jobs')
    } catch (error) {
      console.error('Error deleting job:', error)
      toast.error('Failed to delete job')
    }
  }

  const assignTechnician = async (technicianId: string) => {
    try {
      const { error } = await supabase
        .from('jobs')
        .update({ technician_id: technicianId })
        .eq('id', job.id)

      if (error) throw error

      // Find technician name for display
      const tech = technicians.find(t => t.id === technicianId)
      setJob({ ...job, technician_id: technicianId, profiles: tech })
      toast.success(`Technician ${tech?.full_name} assigned successfully`)
    } catch (error) {
      console.error('Error assigning technician:', error)
      toast.error('Failed to assign technician')
    }
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <Link href="/jobs">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Jobs
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold">Job {job.job_number}</h1>
            <p className="text-muted-foreground">{job.title}</p>
          </div>
          <Badge className={`${getStatusColor(job.status)} text-white`}>
            {job.status?.toUpperCase().replace('_', ' ')}
          </Badge>
        </div>
        <div className="flex gap-2">
          <Button onClick={handleEditClick}>
            <Edit className="h-4 w-4 mr-2" />
            Edit Job
          </Button>
          <Button variant="destructive" onClick={handleDelete}>
            <Trash2 className="h-4 w-4 mr-2" />
            Delete
          </Button>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Assigned Technicians */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                Assigned Technicians
              </CardTitle>
            </CardHeader>
            <CardContent>
              {job.profiles ? (
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <div>
                    <p className="font-medium">{job.profiles.full_name}</p>
                    <p className="text-sm text-muted-foreground">{job.profiles.email}</p>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => assignTechnician('')}
                  >
                    Remove
                  </Button>
                </div>
              ) : (
                <select
                  className="w-full p-2 border rounded"
                  onChange={(e) => e.target.value && assignTechnician(e.target.value)}
                  defaultValue=""
                >
                  <option value="">Add a technician...</option>
                  {technicians.map((tech) => (
                    <option key={tech.id} value={tech.id}>
                      {tech.full_name}
                    </option>
                  ))}
                </select>
              )}
            </CardContent>
          </Card>

          {/* Photos & Videos */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Camera className="h-5 w-5" />
                Photos & Videos
              </CardTitle>
            </CardHeader>
            <CardContent>
              <MediaUpload
                jobId={job.id}
                userId={job.created_by}
                onUploadComplete={loadJobMedia}
              />
              
              {jobPhotos.length > 0 && (
                <div className="mt-4">
                  <p className="text-sm text-muted-foreground mb-2">
                    {jobPhotos.length} photo(s) uploaded
                  </p>
                  <div className="grid grid-cols-3 gap-4">
                    {jobPhotos.map((photo, index) => (
                      <div key={photo.id} className="relative">
                        {photo.media_type === 'video' ? (
                          <div className="w-full h-32 bg-gray-200 rounded flex items-center justify-center">
                            <FileText className="h-8 w-8 text-gray-500" />
                            <span className="text-xs">Video</span>
                          </div>
                        ) : (
                          <img
                            src={photo.url}
                            alt={`Photo ${index + 1}`}
                            className="w-full h-32 object-cover rounded"
                            onError={(e) => {
                              console.error(`Image failed to load: ${photo.url}`)
                              const target = e.target as HTMLImageElement
                              target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjZTVlN2ViIi8+CiAgPHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIyMCIgZmlsbD0iIzZiNzI4MCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9Im1pZGRsZSI+RmFpbGVkIHRvIGxvYWQ8L3RleHQ+Cjwvc3ZnPg=='
                            }}
                            onLoad={() => console.log(`Photo ${index + 1} loaded successfully`)}
                          />
                        )}
                        {photo.caption && (
                          <p className="text-xs mt-1 truncate">{photo.caption}</p>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Documents & Files */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Documents & Files
              </CardTitle>
            </CardHeader>
            <CardContent>
              <FileUpload
                jobId={job.id}
                userId={job.created_by}
                onUploadComplete={loadJobFiles}
              />
              
              {jobFiles.length > 0 && (
                <div className="space-y-2 mt-4">
                  {jobFiles.map((file) => (
                    <div key={file.id} className="flex items-center justify-between p-2 border rounded">
                      <div className="flex items-center gap-2">
                        <FileText className="h-4 w-4" />
                        <div>
                          <p className="text-sm font-medium">{file.file_name}</p>
                          <p className="text-xs text-muted-foreground">
                            {new Date(file.created_at).toLocaleDateString()}
                          </p>
                        </div>
                      </div>
                      <a
                        href={file.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-500 hover:underline text-sm"
                      >
                        View
                      </a>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar - Job Details */}
        <div>
          <Card>
            <CardHeader>
              <CardTitle>Job Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Customer</p>
                <p className="font-medium">{job.customers?.name || 'N/A'}</p>
              </div>
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Job Type</p>
                <p className="font-medium capitalize">{job.job_type || 'N/A'}</p>
              </div>
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Job Overview</p>
                <p className="text-sm">{job.description || 'No description'}</p>
              </div>
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Scheduled Date</p>
                <p className="font-medium">
                  {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : 'Not scheduled'}
                </p>
              </div>
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Scheduled Time</p>
                <p className="font-medium">{job.scheduled_time || 'Not set'}</p>
              </div>
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Service Address</p>
                <p className="text-sm">{job.address || job.customers?.address || 'No address'}</p>
              </div>
              
              {job.total_amount && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Total Value</p>
                  <p className="font-medium text-lg">${job.total_amount.toFixed(2)}</p>
                </div>
              )}
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Payment Status</p>
                <p className="font-medium">{job.payment_status || 'pending'}</p>
              </div>
              
              {job.proposals && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Related Proposal</p>
                  <Link 
                    href={`/proposals/${job.proposal_id}`}
                    className="text-blue-500 hover:underline flex items-center gap-1"
                  >
                    <FileText className="h-3 w-3" />
                    #{job.proposals.proposal_number}
                  </Link>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Edit Job Modal */}
      <Dialog open={isEditModalOpen} onOpenChange={setIsEditModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Edit Job</DialogTitle>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Job Title</Label>
                <Input
                  value={editedJob.title || ''}
                  onChange={(e) => setEditedJob({...editedJob, title: e.target.value})}
                />
              </div>
              <div>
                <Label>Job Type</Label>
                <select
                  className="w-full p-2 border rounded"
                  value={editedJob.job_type || ''}
                  onChange={(e) => setEditedJob({...editedJob, job_type: e.target.value})}
                >
                  <option value="installation">Installation</option>
                  <option value="maintenance">Maintenance</option>
                  <option value="repair">Repair</option>
                  <option value="inspection">Inspection</option>
                </select>
              </div>
            </div>

            <div>
              <Label>Description</Label>
              <Textarea
                value={editedJob.description || ''}
                onChange={(e) => setEditedJob({...editedJob, description: e.target.value})}
                rows={3}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Status</Label>
                <select
                  className="w-full p-2 border rounded"
                  value={editedJob.status || ''}
                  onChange={(e) => setEditedJob({...editedJob, status: e.target.value})}
                >
                  <option value="not_scheduled">Not Scheduled</option>
                  <option value="scheduled">Scheduled</option>
                  <option value="in_progress">In Progress</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
              <div>
                <Label>Assigned Technician</Label>
                <select
                  className="w-full p-2 border rounded"
                  value={editedJob.technician_id || ''}
                  onChange={(e) => setEditedJob({...editedJob, technician_id: e.target.value})}
                >
                  <option value="">Unassigned</option>
                  {technicians.map((tech) => (
                    <option key={tech.id} value={tech.id}>
                      {tech.full_name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Scheduled Date</Label>
                <Input
                  type="date"
                  value={editedJob.scheduled_date || ''}
                  onChange={(e) => setEditedJob({...editedJob, scheduled_date: e.target.value})}
                />
              </div>
              <div>
                <Label>Scheduled Time</Label>
                <Input
                  type="time"
                  value={editedJob.scheduled_time || ''}
                  onChange={(e) => setEditedJob({...editedJob, scheduled_time: e.target.value})}
                />
              </div>
            </div>

            <div>
              <Label>Service Address</Label>
              <Input
                value={editedJob.address || ''}
                onChange={(e) => setEditedJob({...editedJob, address: e.target.value})}
              />
            </div>

            <div>
              <Label>Notes</Label>
              <Textarea
                value={editedJob.notes || ''}
                onChange={(e) => setEditedJob({...editedJob, notes: e.target.value})}
                rows={3}
                placeholder="Add any notes..."
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSaveChanges} disabled={isSaving}>
              {isSaving ? 'Saving...' : 'Save Changes'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
