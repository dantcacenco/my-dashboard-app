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

interface JobDetailViewProps {
  job: any
  userRole: string
}

export default function JobDetailView({ job: initialJob, userRole }: JobDetailViewProps) {
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
  const [uploadingPhoto, setUploadingPhoto] = useState(false)
  const [uploadingFile, setUploadingFile] = useState(false)

  useEffect(() => {
    loadTechnicians()
    loadAssignedTechnicians()
    loadJobPhotos()
    loadJobFiles()
  }, [job.id])

  const loadTechnicians = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
      .eq('is_active', true)
      .order('full_name')
    
    if (data) setTechnicians(data)
  }

  const loadAssignedTechnicians = async () => {
    const { data } = await supabase
      .from('job_technicians')
      .select('*, technician:technician_id(id, full_name, email)')
      .eq('job_id', job.id)
    
    if (data) setAssignedTechnicians(data)
  }

  const loadJobPhotos = async () => {
    const { data } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    if (data) setJobPhotos(data)
  }

  const loadJobFiles = async () => {
    const { data } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    if (data) setJobFiles(data)
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

  const handleAssignTechnician = async (technicianId: string) => {
    const { data: { user } } = await supabase.auth.getUser()
    
    const { error } = await supabase
      .from('job_technicians')
      .insert({
        job_id: job.id,
        technician_id: technicianId,
        assigned_by: user?.id
      })
    
    if (!error) {
      loadAssignedTechnicians()
      toast.success('Technician assigned')
    } else {
      toast.error('Failed to assign technician')
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

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    setUploadingPhoto(true)
    const { data: { user } } = await supabase.auth.getUser()
    const fileName = `${job.id}/${Date.now()}_${file.name}`

    try {
      const { error: uploadError } = await supabase.storage
        .from('job-photos')
        .upload(fileName, file)

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('job-photos')
        .getPublicUrl(fileName)

      const { error: dbError } = await supabase
        .from('job_photos')
        .insert({
          job_id: job.id,
          uploaded_by: user?.id,
          photo_url: publicUrl,
          photo_type: 'general'
        })

      if (dbError) throw dbError

      loadJobPhotos()
      toast.success('Photo uploaded')
    } catch (error) {
      toast.error('Failed to upload photo')
    } finally {
      setUploadingPhoto(false)
    }
  }

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    setUploadingFile(true)
    const { data: { user } } = await supabase.auth.getUser()
    const fileName = `${job.id}/${Date.now()}_${file.name}`

    try {
      const { error: uploadError } = await supabase.storage
        .from('job-files')
        .upload(fileName, file)

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('job-files')
        .getPublicUrl(fileName)

      const { error: dbError } = await supabase
        .from('job_files')
        .insert({
          job_id: job.id,
          uploaded_by: user?.id,
          file_name: file.name,
          file_url: publicUrl,
          file_size: file.size,
          mime_type: file.type
        })

      if (dbError) throw dbError

      loadJobFiles()
      toast.success('File uploaded')
    } catch (error) {
      toast.error('Failed to upload file')
    } finally {
      setUploadingFile(false)
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
                      {job.description || 'No overview available. Click edit to add one.'}
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
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center gap-2">
                      <select
                        className="flex-1 p-2 border rounded-md"
                        onChange={(e) => {
                          if (e.target.value) {
                            handleAssignTechnician(e.target.value)
                            e.target.value = ''
                          }
                        }}
                      >
                        <option value="">Select technician to assign...</option>
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
                            <span>{assignment.technician?.full_name || assignment.technician?.email}</span>
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
                          No technicians assigned yet
                        </p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="photos">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Photos</CardTitle>
                    <label className="cursor-pointer">
                      <input
                        type="file"
                        accept="image/*"
                        className="hidden"
                        onChange={handlePhotoUpload}
                        disabled={uploadingPhoto}
                      />
                      <Button size="sm" disabled={uploadingPhoto}>
                        <Upload className="h-4 w-4 mr-2" />
                        {uploadingPhoto ? 'Uploading...' : 'Upload Photo'}
                      </Button>
                    </label>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                    {jobPhotos.map((photo) => (
                      <div key={photo.id} className="relative group">
                        <img
                          src={photo.photo_url}
                          alt="Job photo"
                          className="w-full h-32 object-cover rounded-md"
                        />
                      </div>
                    ))}
                    {jobPhotos.length === 0 && (
                      <p className="text-gray-500 col-span-full text-center py-8">
                        No photos uploaded yet
                      </p>
                    )}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="files">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Files</CardTitle>
                    <label className="cursor-pointer">
                      <input
                        type="file"
                        className="hidden"
                        onChange={handleFileUpload}
                        disabled={uploadingFile}
                      />
                      <Button size="sm" disabled={uploadingFile}>
                        <Upload className="h-4 w-4 mr-2" />
                        {uploadingFile ? 'Uploading...' : 'Upload File'}
                      </Button>
                    </label>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    {jobFiles.map((file) => (
                      <div key={file.id} className="flex items-center justify-between p-3 border rounded-md">
                        <div className="flex items-center gap-2">
                          <FileText className="h-4 w-4 text-gray-500" />
                          <a 
                            href={file.file_url} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="text-blue-600 hover:underline"
                          >
                            {file.file_name}
                          </a>
                        </div>
                      </div>
                    ))}
                    {jobFiles.length === 0 && (
                      <p className="text-gray-500 text-center py-8">
                        No files uploaded yet
                      </p>
                    )}
                  </div>
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
                <p className="font-medium">{job.customers?.name || 'N/A'}</p>
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
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Edit Job Modal */}
      {showEditModal && (
        <EditJobModal 
          job={job}
          onClose={() => setShowEditModal(false)}
          onSave={(updatedJob) => {
            setJob(updatedJob)
            setShowEditModal(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}

function EditJobModal({ job, onClose, onSave }: any) {
  const [formData, setFormData] = useState({
    customer_id: job.customer_id,
    title: job.title,
    description: job.description || '',
    job_type: job.job_type,
    status: job.status,
    service_address: job.service_address || '',
    service_city: job.service_city || '',
    service_state: job.service_state || '',
    service_zip: job.service_zip || '',
    scheduled_date: job.scheduled_date || '',
    scheduled_time: job.scheduled_time || '',
    notes: job.notes || ''
  })
  const [customers, setCustomers] = useState<any[]>([])
  const [selectedCustomer, setSelectedCustomer] = useState<any>(job.customers)
  const [isLoading, setIsLoading] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    loadCustomers()
  }, [])

  const loadCustomers = async () => {
    const { data } = await supabase
      .from('customers')
      .select('*')
      .order('name')
    
    if (data) setCustomers(data)
  }

  const handleSave = async () => {
    setIsLoading(true)
    
    const { error } = await supabase
      .from('jobs')
      .update(formData)
      .eq('id', job.id)
    
    if (!error) {
      // If customer changed, update customer details
      if (selectedCustomer && selectedCustomer.id !== job.customer_id) {
        await supabase
          .from('customers')
          .update({
            name: selectedCustomer.name,
            email: selectedCustomer.email,
            phone: selectedCustomer.phone,
            address: selectedCustomer.address
          })
          .eq('id', selectedCustomer.id)
      }
      
      toast.success('Job updated successfully')
      onSave({ ...job, ...formData, customers: selectedCustomer })
    } else {
      toast.error('Failed to update job')
    }
    
    setIsLoading(false)
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold">Edit Job</h2>
            <button onClick={onClose}>
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="space-y-4">
            {/* Customer Selection */}
            <div>
              <label className="block text-sm font-medium mb-1">Customer</label>
              <select
                value={formData.customer_id}
                onChange={(e) => {
                  const customer = customers.find(c => c.id === e.target.value)
                  setSelectedCustomer(customer)
                  setFormData({ ...formData, customer_id: e.target.value })
                }}
                className="w-full p-2 border rounded-md"
              >
                {customers.map(customer => (
                  <option key={customer.id} value={customer.id}>
                    {customer.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Customer Details (editable) */}
            {selectedCustomer && (
              <div className="p-4 bg-gray-50 rounded-md space-y-3">
                <h3 className="font-medium">Customer Details</h3>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm text-gray-600">Name</label>
                    <input
                      type="text"
                      value={selectedCustomer.name}
                      onChange={(e) => setSelectedCustomer({ ...selectedCustomer, name: e.target.value })}
                      className="w-full p-2 border rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-600">Email</label>
                    <input
                      type="email"
                      value={selectedCustomer.email || ''}
                      onChange={(e) => setSelectedCustomer({ ...selectedCustomer, email: e.target.value })}
                      className="w-full p-2 border rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-600">Phone</label>
                    <input
                      type="text"
                      value={selectedCustomer.phone || ''}
                      onChange={(e) => setSelectedCustomer({ ...selectedCustomer, phone: e.target.value })}
                      className="w-full p-2 border rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-600">Address</label>
                    <input
                      type="text"
                      value={selectedCustomer.address || ''}
                      onChange={(e) => setSelectedCustomer({ ...selectedCustomer, address: e.target.value })}
                      className="w-full p-2 border rounded-md"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Job Details */}
            <div>
              <label className="block text-sm font-medium mb-1">Job Title</label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                className="w-full p-2 border rounded-md"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">Job Type</label>
                <select
                  value={formData.job_type}
                  onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
                  className="w-full p-2 border rounded-md"
                >
                  <option value="installation">Installation</option>
                  <option value="repair">Repair</option>
                  <option value="maintenance">Maintenance</option>
                  <option value="inspection">Inspection</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">Status</label>
                <select
                  value={formData.status}
                  onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                  className="w-full p-2 border rounded-md"
                >
                  <option value="not_scheduled">Not Scheduled</option>
                  <option value="scheduled">Scheduled</option>
                  <option value="in_progress">In Progress</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>

            {/* Service Location */}
            <div>
              <label className="block text-sm font-medium mb-1">Service Address</label>
              <input
                type="text"
                value={formData.service_address}
                onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
                className="w-full p-2 border rounded-md"
                placeholder="123 Main St"
              />
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">City</label>
                <input
                  type="text"
                  value={formData.service_city}
                  onChange={(e) => setFormData({ ...formData, service_city: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">State</label>
                <input
                  type="text"
                  value={formData.service_state}
                  onChange={(e) => setFormData({ ...formData, service_state: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">ZIP</label>
                <input
                  type="text"
                  value={formData.service_zip}
                  onChange={(e) => setFormData({ ...formData, service_zip: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
            </div>

            {/* Scheduling */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">Scheduled Date</label>
                <input
                  type="date"
                  value={formData.scheduled_date}
                  onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Scheduled Time</label>
                <input
                  type="time"
                  value={formData.scheduled_time}
                  onChange={(e) => setFormData({ ...formData, scheduled_time: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
            </div>

            {/* Overview */}
            <div>
              <label className="block text-sm font-medium mb-1">Overview</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                className="w-full p-2 border rounded-md h-24"
                placeholder="Job overview..."
              />
            </div>

            {/* Notes */}
            <div>
              <label className="block text-sm font-medium mb-1">Notes</label>
              <textarea
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                className="w-full p-2 border rounded-md h-24"
                placeholder="Additional notes..."
              />
            </div>
          </div>

          <div className="flex justify-end gap-2 mt-6">
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={isLoading}>
              {isLoading ? 'Saving...' : 'Save Changes'}
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
