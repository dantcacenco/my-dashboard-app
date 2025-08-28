'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  ArrowLeft, Edit, Calendar, Clock, MapPin, User,
  FileText, Camera, Upload, Plus, X, Save, Trash2,
  DollarSign, Link as LinkIcon, FileCheck
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'
import { getUnifiedDisplayStatus, syncJobProposalStatus } from '@/lib/status-sync'
import MediaUpload from '@/components/uploads/MediaUpload'
import FileUpload from '@/components/uploads/FileUpload'
import MediaViewer from '@/components/MediaViewer'
import VideoThumbnail from '@/components/VideoThumbnail'
import { EditJobModal } from './EditJobModal'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

interface JobDetailViewProps {
  job: any
  userId?: string
  userRole?: string // Added this prop to fix TypeScript error
}

export default function JobDetailView({ job, userId, userRole: initialUserRole }: JobDetailViewProps) {
  const router = useRouter()
  const supabase = createClient()
  
  // State - Added setJob to fix TypeScript error
  const [currentJob, setJob] = useState(job)
  const [jobPhotos, setJobPhotos] = useState<any[]>([])
  const [jobFiles, setJobFiles] = useState<any[]>([])
  const [currentUserId, setCurrentUserId] = useState(userId || '')
  const [viewerOpen, setViewerOpen] = useState(false)
  const [viewerItems, setViewerItems] = useState<any[]>([])
  const [viewerIndex, setViewerIndex] = useState(0)
  const [proposal, setProposal] = useState<any>(null)
  const [technicians, setTechnicians] = useState<any[]>([])
  const [assignedTechnicians, setAssignedTechnicians] = useState<any[]>([])
  const [userRole, setUserRole] = useState(initialUserRole || 'technician')
  const [isEditingNotes, setIsEditingNotes] = useState(false)
  const [notesText, setNotesText] = useState(currentJob.notes || '')
  const [showEditModal, setShowEditModal] = useState(false)
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [photosExpanded, setPhotosExpanded] = useState(false)
  const [filesExpanded, setFilesExpanded] = useState(false)

  useEffect(() => {
    console.log('=== JOB DETAIL VIEW DEBUG START ===')
    console.log('Job ID:', currentJob.id)
    console.log('Job Number:', currentJob.job_number)
    console.log('User ID:', currentUserId)
    console.log('User Role:', userRole)
    
    loadTechnicians()
    loadAssignedTechnicians()
    loadJobMedia()
    loadJobFiles()
    loadProposal()
    if (!userId) {
      getCurrentUser()
    }
  }, [currentJob.id])

  const getCurrentUser = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      setCurrentUserId(user.id)
      
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()
      
      setUserRole(profile?.role || 'technician')
    }
  }

  const loadProposal = async () => {
    if (currentJob.proposal_id) {
      const { data } = await supabase
        .from('proposals')
        .select(`
          *,
          customers!inner (
            id,
            name,
            email,
            phone,
            address
          )
        `)
        .eq('id', currentJob.proposal_id)
        .single()
      
      if (data) {
        setProposal(data)
      }
    }
  }

  const loadTechnicians = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('id, email, full_name, role')
      .eq('role', 'technician')
      .eq('is_active', true)

    setTechnicians(data || [])
  }

  const loadAssignedTechnicians = async () => {
    console.log('=== TECHNICIAN DEBUG START ===', { jobId: currentJob.id, jobNumber: currentJob.job_number })
    
    const { data } = await supabase
      .from('job_technicians')
      .select(`
        *,
        profiles!technician_id (
          id,
          email,
          full_name,
          role
        )
      `)
      .eq('job_id', currentJob.id)

    console.log('Technician query result:', { data, count: data?.length || 0 })
    const processedData = data?.map((item: any) => item.profiles) || []
    console.log('Processed technician data:', processedData)
    setAssignedTechnicians(processedData)
  }

  const loadJobMedia = async () => {
    const { data } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', currentJob.id)
      .order('created_at', { ascending: true })

    setJobPhotos(data || [])
  }

  const loadJobFiles = async () => {
    console.log('=== LOADING JOB FILES DEBUG ===')
    console.log('Job ID for files:', currentJob.id)
    
    const { data, error } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', currentJob.id)
      .order('created_at', { ascending: false })

    console.log('Job files query result:', { data, error, count: data?.length || 0 })
    
    if (data) {
      console.log('Individual files:')
      data.forEach((file, index) => {
        console.log(`File ${index}:`, {
          id: file.id,
          name: file.file_name,
          url: file.file_url,
          created: file.created_at
        })
      })
    }
    
    setJobFiles(data || [])
  }

  const handleSaveNotes = async () => {
    try {
      const { error } = await supabase
        .from('jobs')
        .update({ notes: notesText })
        .eq('id', currentJob.id)

      if (error) throw error

      setJob({ ...currentJob, notes: notesText })
      setIsEditingNotes(false)
      toast.success('Notes saved successfully')
    } catch (error) {
      console.error('Error saving notes:', error)
      toast.error('Failed to save notes')
    }
  }

  const handleStatusUpdate = async (newStatus: string) => {
    try {
      // Update job status
      const { error: jobError } = await supabase
        .from('jobs')
        .update({ status: newStatus })
        .eq('id', currentJob.id)

      if (jobError) throw jobError

      // Sync proposal status if proposal exists
      if (currentJob.proposal_id) {
        await syncJobProposalStatus(
          supabase,
          currentJob.id,
          currentJob.proposal_id,
          newStatus,
          'job'
        )
      }

      // Update local state
      setJob({ ...currentJob, status: newStatus })
      
      // Reload proposal to reflect changes
      if (currentJob.proposal_id) {
        loadProposal()
      }

      toast.success('Status updated successfully')
    } catch (error) {
      console.error('Error updating status:', error)
      toast.error('Failed to update status')
    }
  }

  const handleTechnicianToggle = async (techId: string) => {
    const isAssigned = assignedTechnicians.some(t => t.id === techId)
    
    try {
      if (isAssigned) {
        const { error } = await supabase
          .from('job_technicians')
          .delete()
          .eq('job_id', currentJob.id)
          .eq('technician_id', techId)

        if (error) throw error
        
        await loadAssignedTechnicians()
        toast.success('Technician removed')
      } else {
        const { data: existing } = await supabase
          .from('job_technicians')
          .select('id')
          .eq('job_id', currentJob.id)
          .eq('technician_id', techId)
          .single()
        
        if (!existing) {
          const { error } = await supabase
            .from('job_technicians')
            .insert({
              job_id: currentJob.id,
              technician_id: techId
            })

          if (error) throw error
          
          await loadAssignedTechnicians()
          toast.success('Technician assigned')
        } else {
          toast.info('Technician already assigned')
        }
      }
    } catch (error) {
      console.error('Error toggling technician:', error)
      toast.error('Failed to update technician assignment')
    }
  }

  const handleDeleteJob = async () => {
    setIsDeleting(true)

    try {
      await supabase
        .from('job_technicians')
        .delete()
        .eq('job_id', currentJob.id)

      await supabase
        .from('job_photos')
        .delete()
        .eq('job_id', currentJob.id)

      await supabase
        .from('job_files')
        .delete()
        .eq('job_id', currentJob.id)

      const { error } = await supabase
        .from('jobs')
        .delete()
        .eq('id', currentJob.id)

      if (error) throw error

      toast.success('Job deleted successfully')
      router.push('/jobs')
    } catch (error) {
      console.error('Error deleting job:', error)
      toast.error('Failed to delete job')
      setIsDeleting(false)
    }
  }

  const openMediaViewer = (photos: any[], index: number) => {
    console.log('Opening media viewer for photos:', { count: photos.length, index })
    
    const items = photos.map(photo => ({
      id: photo.id,
      url: photo.photo_url,
      name: photo.caption || 'Media',
      caption: photo.caption,
      type: photo.mime_type?.startsWith('video/') ? 'video' : 'photo',
      mime_type: photo.mime_type
    }))
    
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }

  const openFileViewer = (files: any[], index: number) => {
    console.log('=== FILE VIEWER CLICKED ===')
    console.log('Files array:', files)
    console.log('Index clicked:', index)
    console.log('File being opened:', files[index])
    
    const items = files.map(file => ({
      id: file.id,
      url: file.file_url,
      name: file.file_name,
      caption: file.file_name,
      type: 'file',
      mime_type: file.mime_type || 'application/octet-stream'
    }))
    
    console.log('MediaViewer items:', items)
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
    console.log('MediaViewer should now open')
  }

  const formatJobOverview = (description: string | null | undefined) => {
    if (!description) return 'No overview available'
    
    return description.split('\n').map((line, index) => {
      if (line.includes('SERVICES:') || line.includes('ADD-ONS:')) {
        return (
          <div key={index} className="font-semibold text-gray-900 mt-4 mb-2">
            {line}
          </div>
        )
      }
      
      if (line.trim().startsWith('- ') || line.trim().startsWith('• ')) {
        return (
          <div key={index} className="ml-4 text-gray-700">
            {line}
          </div>
        )
      }
      
      return (
        <div key={index} className="text-gray-700">
          {line}
        </div>
      )
    })
  }

  const getStatusBadge = (jobStatus: string, proposalStatus?: string) => {
    const displayStatus = getUnifiedDisplayStatus(jobStatus, proposalStatus || '')
    
    const statusColors = {
      'Draft': 'bg-gray-100 text-gray-800',
      'Sent': 'bg-blue-100 text-blue-800',
      'Viewed': 'bg-purple-100 text-purple-800',
      'Approved': 'bg-green-100 text-green-800',
      'Scheduled': 'bg-blue-100 text-blue-800',
      'In Progress': 'bg-yellow-100 text-yellow-800',
      'Completed': 'bg-green-100 text-green-800',
      'Cancelled': 'bg-red-100 text-red-800',
      'Rejected': 'bg-red-100 text-red-800',
    }
    
    return (
      <Badge className={statusColors[displayStatus as keyof typeof statusColors] || 'bg-gray-100 text-gray-800'}>
        {displayStatus}
      </Badge>
    )
  }

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="flex justify-between items-start mb-6">
        <div className="flex items-start gap-4">
          <Link href="/jobs">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold">Job {currentJob.job_number}</h1>
            <p className="text-muted-foreground">{currentJob.title}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {getStatusBadge(currentJob.status, proposal?.status)}
          {userRole === 'boss' && (
            <Button
              variant="destructive"
              size="sm"
              onClick={() => setShowDeleteModal(true)}
            >
              <Trash2 className="h-4 w-4 mr-2" />
              Delete
            </Button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                Assigned Technicians
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {assignedTechnicians.length === 0 && userRole !== 'boss' && (
                  <p className="text-muted-foreground">No technicians assigned yet</p>
                )}
                {assignedTechnicians.map((tech) => (
                  <div key={tech.id} className="flex items-center justify-between p-2 bg-accent rounded">
                    <span>{tech.full_name || tech.email}</span>
                    {userRole === 'boss' && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleTechnicianToggle(tech.id)}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                ))}

                {userRole === 'boss' && (
                  <select
                    className="w-full p-2 border rounded"
                    value=""
                    onChange={(e) => {
                      if (e.target.value) {
                        handleTechnicianToggle(e.target.value)
                        e.target.value = ''
                      }
                    }}
                  >
                    <option value="">Add a technician...</option>
                    {technicians
                      .filter(t => !assignedTechnicians.some(at => at.id === t.id))
                      .map(tech => (
                        <option key={tech.id} value={tech.id}>
                          {tech.full_name || tech.email}
                        </option>
                      ))}
                  </select>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Camera className="h-5 w-5" />
                Photos & Videos
              </CardTitle>
            </CardHeader>
            <CardContent>
              {currentUserId && (
                <MediaUpload
                  jobId={currentJob.id}
                  userId={currentUserId}
                  onUploadComplete={loadJobMedia}
                />
              )}

              {jobPhotos.length > 0 && (
                <div>
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-4">
                    {(photosExpanded ? jobPhotos : jobPhotos.slice(0, 3)).map((photo, index) => (
                      <div
                        key={photo.id}
                        className="relative group cursor-pointer"
                        onClick={() => openMediaViewer(jobPhotos, index)}
                      >
                        {photo.mime_type?.startsWith('video/') ? (
                          <VideoThumbnail videoUrl={photo.photo_url} onClick={() => openMediaViewer(jobPhotos, index)} />
                        ) : (
                          <img
                            src={photo.photo_url}
                            alt={photo.caption || 'Job photo'}
                            className="w-full h-32 object-cover rounded hover:opacity-90 transition"
                          />
                        )}
                        {photo.caption && (
                          <div className="absolute bottom-0 left-0 right-0 bg-black/50 text-white text-xs p-2 rounded-b">
                            {photo.caption}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                  {jobPhotos.length > 3 && (
                    <div className="flex justify-center mt-4">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPhotosExpanded(!photosExpanded)}
                      >
                        {photosExpanded ? 'Collapse' : `Expand (${jobPhotos.length - 3} more)`}
                      </Button>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Documents & Files
              </CardTitle>
            </CardHeader>
            <CardContent>
              {currentUserId && (
                <FileUpload
                  jobId={currentJob.id}
                  userId={currentUserId}
                  onUploadComplete={loadJobFiles}
                />
              )}

              {jobFiles.length > 0 && (
                <div>
                  <div className="space-y-2 mt-4">
                    {(filesExpanded ? jobFiles : jobFiles.slice(0, 3)).map((file, index) => (
                      <div key={file.id} className="flex items-center justify-between p-3 border rounded hover:bg-gray-50">
                        <div 
                          className="flex items-center gap-3 flex-1 cursor-pointer"
                          onClick={() => {
                            console.log('FILE NAME CLICKED!', file.file_name, 'Index:', index);
                            openFileViewer(jobFiles, index);
                          }}
                        >
                          <FileText className="h-5 w-5 text-muted-foreground" />
                          <div>
                            <p className="font-medium text-blue-600 hover:text-blue-800">
                              {file.file_name}
                            </p>
                            <p className="text-sm text-muted-foreground">
                              {new Date(file.created_at).toLocaleDateString()}
                            </p>
                          </div>
                        </div>
                        <div className="text-xs text-gray-500">
                          Click filename to view
                        </div>
                      </div>
                    ))}
                  </div>
                  {jobFiles.length > 3 && (
                    <div className="flex justify-center mt-4">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setFilesExpanded(!filesExpanded)}
                      >
                        {filesExpanded ? 'Collapse' : `Expand (${jobFiles.length - 3} more)`}
                      </Button>
                    </div>
                  )}
                </div>
              )}

              {jobFiles.length === 0 && (
                <p className="text-muted-foreground">No files uploaded yet</p>
              )}
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>Job Details</CardTitle>
              {userRole === 'boss' && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setShowEditModal(true)}
                >
                  <Edit className="h-4 w-4 mr-1" />
                  Edit
                </Button>
              )}
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div>
                  <h3 className="font-medium">Customer</h3>
                  <p className="text-muted-foreground">{currentJob.customers?.name || 'No customer assigned'}</p>
                </div>

                <div>
                  <h3 className="font-medium">Job Type</h3>
                  <p className="text-muted-foreground">{currentJob.job_type}</p>
                </div>

                <div>
                  <h3 className="font-medium">Job Overview</h3>
                  <div className="text-sm text-muted-foreground">
                    {formatJobOverview(currentJob.description)}
                  </div>
                </div>

                {currentJob.scheduled_date && (
                  <div>
                    <h3 className="font-medium">Scheduled Date</h3>
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Calendar className="h-4 w-4" />
                      {new Date(currentJob.scheduled_date).toLocaleDateString()}
                    </div>
                  </div>
                )}

                {currentJob.scheduled_time && (
                  <div>
                    <h3 className="font-medium">Scheduled Time</h3>
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Clock className="h-4 w-4" />
                      {currentJob.scheduled_time}
                    </div>
                  </div>
                )}

                {currentJob.service_address && (
                  <div>
                    <h3 className="font-medium">Service Address</h3>
                    <div className="flex items-start gap-2 text-muted-foreground">
                      <MapPin className="h-4 w-4 mt-1 flex-shrink-0" />
                      <p>{currentJob.service_address}</p>
                    </div>
                  </div>
                )}

                {proposal && (
                  <div>
                    <h3 className="font-medium">Related Proposal</h3>
                    <Link href={`/proposals/${proposal.id}`}>
                      <Button variant="outline" size="sm" className="w-full justify-start">
                        <LinkIcon className="h-4 w-4 mr-1" />
                        #{proposal.proposal_number} - ${proposal.total}
                      </Button>
                    </Link>
                  </div>
                )}

                <div>
                  <h3 className="font-medium mb-2">Notes</h3>
                  {isEditingNotes ? (
                    <div className="space-y-2">
                      <textarea
                        value={notesText}
                        onChange={(e) => setNotesText(e.target.value)}
                        className="w-full p-2 border rounded-md resize-none"
                        rows={4}
                        placeholder="Add notes about this job..."
                      />
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setNotesText(currentJob.notes || '')
                            setIsEditingNotes(false)
                          }}
                        >
                          Cancel
                        </Button>
                        <Button size="sm" onClick={handleSaveNotes}>
                          <Save className="h-4 w-4 mr-1" />
                          Save
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <div
                      className="min-h-[40px] p-2 border rounded-md cursor-pointer hover:bg-gray-50"
                      onClick={() => setIsEditingNotes(true)}
                    >
                      {currentJob.notes || (
                        <span className="text-muted-foreground">
                          Click to add notes...
                        </span>
                      )}
                    </div>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {viewerOpen && (
        <MediaViewer
          items={viewerItems}
          initialIndex={viewerIndex}
          onClose={() => setViewerOpen(false)}
        />
      )}

      <EditJobModal
        job={currentJob}
        isOpen={showEditModal}
        onClose={() => setShowEditModal(false)}
        onJobUpdated={async () => {
          setShowEditModal(false)
          toast.success('Job updated successfully')
        }}
      />

      <Dialog open={showDeleteModal} onOpenChange={setShowDeleteModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Job</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this job? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowDeleteModal(false)}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDeleteJob}
              disabled={isDeleting}
            >
              {isDeleting ? 'Deleting...' : 'Delete Job'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
