'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  ArrowLeft, Edit, Calendar, Clock, MapPin, User, 
  FileText, Camera, Upload, Plus, X, Save, Trash2 
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'
import { EditJobModal } from './EditJobModal'
import PhotoUpload from '@/components/uploads/PhotoUpload'
import FileUpload from '@/components/uploads/FileUpload'

interface JobDetailViewProps {
  job: any
  userRole: string
  userId: string
}

export default function JobDetailView({ job: initialJob, userRole, userId }: JobDetailViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [job, setJob] = useState(initialJob)
  const [isEditingOverview, setIsEditingOverview] = useState(false)
  const [overviewText, setOverviewText] = useState(job.description || '')
  const [isEditingNotes, setIsEditingNotes] = useState(false)
  const [notesText, setNotesText] = useState(job.notes || '')
  const [showEditModal, setShowEditModal] = useState(false)
  const [technicians, setTechnicians] = useState<any[]>([])
  const [assignedTechnicians, setAssignedTechnicians] = useState<any[]>([])
  const [jobPhotos, setJobPhotos] = useState<any[]>([])
  const [jobFiles, setJobFiles] = useState<any[]>([])

  useEffect(() => {
    loadTechnicians()
    loadAssignedTechnicians()
    loadJobMedia()
  }, [job.id])

  const loadTechnicians = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
      .eq('is_active', true)
    
    setTechnicians(data || [])
  }

  const loadAssignedTechnicians = async () => {
    const { data } = await supabase
      .from('job_technicians')
      .select('*, profiles!technician_id(*)')
      .eq('job_id', job.id)
    
    setAssignedTechnicians(data || [])
  }

  const loadJobMedia = async () => {
    // Load photos
    const { data: photos } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    setJobPhotos(photos || [])

    // Load files
    const { data: files } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    setJobFiles(files || [])
  }

  const handleSaveOverview = async () => {
    const { error } = await supabase
      .from('jobs')
      .update({ description: overviewText })
      .eq('id', job.id)

    if (!error) {
      setJob({ ...job, description: overviewText })
      setIsEditingOverview(false)
      toast.success('Overview updated')
    } else {
      toast.error('Failed to update overview')
    }
  }

  const handleSaveNotes = async () => {
    const { error } = await supabase
      .from('jobs')
      .update({ notes: notesText })
      .eq('id', job.id)

    if (!error) {
      setJob({ ...job, notes: notesText })
      setIsEditingNotes(false)
      toast.success('Notes updated')
    } else {
      toast.error('Failed to update notes')
    }
  }

  const handleAddTechnician = async (technicianId: string) => {
    const { error } = await supabase
      .from('job_technicians')
      .insert({
        job_id: job.id,
        technician_id: technicianId
      })

    if (!error) {
      loadAssignedTechnicians()
      toast.success('Technician added')
    } else {
      toast.error('Failed to add technician')
    }
  }

  const handleRemoveTechnician = async (assignmentId: string) => {
    const { error } = await supabase
      .from('job_technicians')
      .delete()
      .eq('id', assignmentId)

    if (!error) {
      loadAssignedTechnicians()
      toast.success('Technician removed')
    } else {
      toast.error('Failed to remove technician')
    }
  }

  const deletePhoto = async (photoId: string) => {
    if (!confirm('Are you sure you want to delete this photo?')) return

    const { error } = await supabase
      .from('job_photos')
      .delete()
      .eq('id', photoId)

    if (!error) {
      setJobPhotos(prev => prev.filter(p => p.id !== photoId))
      toast.success('Photo deleted')
    } else {
      toast.error('Failed to delete photo')
    }
  }

  const deleteFile = async (fileId: string) => {
    if (!confirm('Are you sure you want to delete this file?')) return

    const { error } = await supabase
      .from('job_files')
      .delete()
      .eq('id', fileId)

    if (!error) {
      setJobFiles(prev => prev.filter(f => f.id !== fileId))
      toast.success('File deleted')
    } else {
      toast.error('Failed to delete file')
    }
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'not_scheduled': 'bg-gray-100 text-gray-800',
      'scheduled': 'bg-blue-100 text-blue-800',
      'in_progress': 'bg-yellow-100 text-yellow-800',
      'completed': 'bg-green-100 text-green-800',
      'cancelled': 'bg-red-100 text-red-800'
    }
    return colors[status] || 'bg-gray-100 text-gray-800'
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
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
          <Badge className={getStatusColor(job.status)}>
            {job.status.replace('_', ' ').toUpperCase()}
          </Badge>
        </div>
        <Button onClick={() => setShowEditModal(true)}>
          <Edit className="h-4 w-4 mr-2" />
          Edit Job
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <Tabs defaultValue="overview" className="w-full">
            <TabsList className="grid w-full grid-cols-5">
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="technicians">Technicians</TabsTrigger>
              <TabsTrigger value="photos">Photos</TabsTrigger>
              <TabsTrigger value="files">Files</TabsTrigger>
              <TabsTrigger value="notes">Notes</TabsTrigger>
            </TabsList>

            <TabsContent value="overview">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Overview</CardTitle>
                    {!isEditingOverview && (
                      <Button size="sm" variant="outline" onClick={() => setIsEditingOverview(true)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  {isEditingOverview ? (
                    <div className="space-y-4">
                      <textarea
                        value={overviewText}
                        onChange={(e) => setOverviewText(e.target.value)}
                        className="w-full h-32 p-3 border rounded-md"
                        placeholder="Enter job overview..."
                      />
                      <div className="flex gap-2">
                        <Button size="sm" onClick={handleSaveOverview}>
                          <Save className="h-4 w-4 mr-2" />
                          Save
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          onClick={() => {
                            setIsEditingOverview(false)
                            setOverviewText(job.description || '')
                          }}
                        >
                          Cancel
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <p className="text-gray-700">
                      {job.description || 'No overview available. Click edit to add an overview.'}
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="technicians">
              <Card>
                <CardHeader>
                  <CardTitle>Assigned Technicians</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <select
                      onChange={(e) => e.target.value && handleAddTechnician(e.target.value)}
                      className="w-full p-2 border rounded-md"
                      defaultValue=""
                    >
                      <option value="">Add a technician...</option>
                      {technicians
                        .filter(t => !assignedTechnicians.find(at => at.technician_id === t.id))
                        .map(tech => (
                          <option key={tech.id} value={tech.id}>
                            {tech.full_name || tech.email}
                          </option>
                        ))}
                    </select>
                  </div>
                  
                  <div className="space-y-2">
                    {assignedTechnicians.map((assignment) => (
                      <div key={assignment.id} className="flex items-center justify-between p-3 border rounded-md">
                        <div className="flex items-center gap-2">
                          <User className="h-4 w-4 text-gray-500" />
                          <span>{assignment.profiles?.full_name || assignment.profiles?.email}</span>
                        </div>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleRemoveTechnician(assignment.id)}
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    ))}
                    {assignedTechnicians.length === 0 && (
                      <p className="text-gray-500 text-center py-4">
                        No technicians assigned
                      </p>
                    )}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="photos">
              <Card>
                <CardHeader>
                  <CardTitle>Job Photos</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <PhotoUpload 
                    jobId={job.id} 
                    userId={userId} 
                    onUploadComplete={loadJobMedia}
                  />
                  
                  {jobPhotos.length > 0 && (
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                      {jobPhotos.map((photo) => (
                        <div key={photo.id} className="relative group">
                          <a 
                            href={photo.photo_url} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="block aspect-square overflow-hidden rounded-lg bg-gray-100"
                          >
                            <img 
                              src={photo.photo_url} 
                              alt={photo.caption || 'Job photo'}
                              className="w-full h-full object-cover hover:scale-105 transition-transform"
                            />
                          </a>
                          <button
                            onClick={() => deletePhoto(photo.id)}
                            className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1.5 opacity-0 group-hover:opacity-100 transition-opacity"
                          >
                            <X className="h-3 w-3" />
                          </button>
                          {photo.caption && (
                            <p className="text-xs text-gray-600 mt-1 truncate">{photo.caption}</p>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                  
                  {jobPhotos.length === 0 && (
                    <p className="text-gray-500 text-center py-8">
                      No photos uploaded yet
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="files">
              <Card>
                <CardHeader>
                  <CardTitle>Job Files</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <FileUpload 
                    jobId={job.id} 
                    userId={userId} 
                    onUploadComplete={loadJobMedia}
                  />
                  
                  {jobFiles.length > 0 && (
                    <div className="space-y-2">
                      {jobFiles.map((file) => (
                        <div key={file.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100">
                          <a 
                            href={file.file_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-3 flex-1 min-w-0"
                          >
                            <FileText className="h-5 w-5 text-gray-500 flex-shrink-0" />
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium truncate hover:text-blue-600">
                                {file.file_name}
                              </p>
                              <p className="text-xs text-gray-500">
                                {file.file_size ? `${(file.file_size / 1024 / 1024).toFixed(2)} MB` : 'Unknown size'}
                              </p>
                            </div>
                          </a>
                          <button
                            onClick={() => deleteFile(file.id)}
                            className="text-red-500 hover:text-red-700 p-2"
                          >
                            <X className="h-4 w-4" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                  
                  {jobFiles.length === 0 && (
                    <p className="text-gray-500 text-center py-8">
                      No files uploaded yet
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="notes">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Notes</CardTitle>
                    {!isEditingNotes && (
                      <Button size="sm" variant="outline" onClick={() => setIsEditingNotes(true)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  {isEditingNotes ? (
                    <div className="space-y-4">
                      <textarea
                        value={notesText}
                        onChange={(e) => setNotesText(e.target.value)}
                        className="w-full h-32 p-3 border rounded-md"
                        placeholder="Enter job notes..."
                      />
                      <div className="flex gap-2">
                        <Button size="sm" onClick={handleSaveNotes}>
                          <Save className="h-4 w-4 mr-2" />
                          Save
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          onClick={() => {
                            setIsEditingNotes(false)
                            setNotesText(job.notes || '')
                          }}
                        >
                          Cancel
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <p className="text-gray-700">
                      {job.notes || 'No notes available. Click edit to add notes.'}
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Job Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-muted-foreground">Customer</p>
                <p className="font-medium">{job.customers?.name || job.customer_name || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Job Type</p>
                <p className="font-medium">{job.job_type}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Scheduled Date</p>
                <p className="font-medium">
                  {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : 'Not scheduled'}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Service Address</p>
                <p className="font-medium">
                  {job.service_address || 'No address specified'}
                </p>
              </div>
              {userRole === 'boss' && (
                <>
                  <div>
                    <p className="text-sm text-muted-foreground">Total Amount</p>
                    <p className="font-medium">
                      ${job.total_amount ? job.total_amount.toFixed(2) : '0.00'}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Amount Paid</p>
                    <p className="font-medium">
                      ${job.amount_paid ? job.amount_paid.toFixed(2) : '0.00'}
                    </p>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        </div>
      {/* Edit Job Modal */}
      {showEditModal && (
        <EditJobModal 
          job={job}
          isOpen={showEditModal}
          onClose={() => setShowEditModal(false)}
          onJobUpdated={() => {
            setShowEditModal(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}
