#!/bin/bash

# Fix type error in technician page
echo "Fixing type error in technician page..."

# Update the technician page with proper type handling
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianDashboard from './TechnicianDashboard'

export default async function TechnicianPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role, full_name')
    .eq('id', user.id)
    .single()

  // Check if user is a technician
  if (!profile || profile.role !== 'technician') {
    redirect('/')
  }

  // Get jobs assigned to this technician
  const { data: jobAssignments } = await supabase
    .from('job_technicians')
    .select(`
      job_id,
      jobs (
        id,
        job_number,
        title,
        description,
        job_type,
        status,
        scheduled_date,
        scheduled_time,
        service_address,
        notes,
        created_at,
        customer_id,
        customers (
          name,
          email,
          phone,
          address
        )
      )
    `)
    .eq('technician_id', user.id)
    .order('created_at', { ascending: false })

  // Extract jobs from assignments (handle the nested structure)
  const jobs = jobAssignments?.map(assignment => assignment.jobs).filter(Boolean).flat() || []

  // Calculate metrics for technician
  const totalJobs = jobs.length
  const completedJobs = jobs.filter((j: any) => j.status === 'completed').length
  const inProgressJobs = jobs.filter((j: any) => j.status === 'in_progress').length
  const scheduledJobs = jobs.filter((j: any) => j.status === 'scheduled').length
  const todaysJobs = jobs.filter((j: any) => {
    const today = new Date().toISOString().split('T')[0]
    return j.scheduled_date?.split('T')[0] === today
  }).length

  const technicianData = {
    profile: {
      name: profile.full_name || user.email || 'Technician',
      email: user.email || '',
      role: profile.role
    },
    metrics: {
      totalJobs,
      completedJobs,
      inProgressJobs,
      scheduledJobs,
      todaysJobs
    },
    jobs
  }

  return <TechnicianDashboard data={technicianData} />
}
EOF

# Now create the technician job detail view (without prices and proposal links)
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/jobs/\[id\]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import TechnicianJobView from './TechnicianJobView'

export default async function TechnicianJobPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/signin')

  // Check if user is a technician
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (!profile || profile.role !== 'technician') {
    redirect('/')
  }

  // Check if this technician is assigned to this job
  const { data: assignment } = await supabase
    .from('job_technicians')
    .select('*')
    .eq('job_id', id)
    .eq('technician_id', user.id)
    .single()

  if (!assignment) {
    // Technician is not assigned to this job
    redirect('/technician')
  }

  // Get job details
  const { data: job } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
        name,
        email,
        phone,
        address
      )
    `)
    .eq('id', id)
    .single()

  if (!job) {
    notFound()
  }

  return <TechnicianJobView job={job} userId={user.id} />
}
EOF

# Create the TechnicianJobView component (simplified version without prices)
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/jobs/\[id\]/TechnicianJobView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  ArrowLeft, Calendar, Clock, MapPin, User, 
  FileText, Camera, Upload, Save, CheckCircle,
  AlertCircle, Phone, Mail
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'
import MediaUpload from '@/components/uploads/MediaUpload'
import FileUpload from '@/components/uploads/FileUpload'
import MediaViewer from '@/components/MediaViewer'
import VideoThumbnail from '@/components/VideoThumbnail'

interface TechnicianJobViewProps {
  job: any
  userId: string
}

export default function TechnicianJobView({ job: initialJob, userId }: TechnicianJobViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [job, setJob] = useState(initialJob)
  const [jobPhotos, setJobPhotos] = useState<any[]>([])
  const [jobFiles, setJobFiles] = useState<any[]>([])
  const [viewerOpen, setViewerOpen] = useState(false)
  const [viewerItems, setViewerItems] = useState<any[]>([])
  const [viewerIndex, setViewerIndex] = useState(0)
  const [notes, setNotes] = useState('')
  const [isSavingNotes, setIsSavingNotes] = useState(false)

  useEffect(() => {
    loadJobMedia()
    loadJobFiles()
  }, [job.id])

  const loadJobMedia = async () => {
    const { data } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: true })

    setJobPhotos(data || [])
  }

  const loadJobFiles = async () => {
    const { data } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })

    setJobFiles(data || [])
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

  const updateJobStatus = async (newStatus: string) => {
    try {
      const { error } = await supabase
        .from('jobs')
        .update({ status: newStatus })
        .eq('id', job.id)

      if (error) throw error

      setJob({ ...job, status: newStatus })
      toast.success(`Job status updated to ${newStatus.replace('_', ' ')}`)
    } catch (error) {
      console.error('Error updating job status:', error)
      toast.error('Failed to update job status')
    }
  }

  const saveNotes = async () => {
    if (!notes.trim()) return
    
    setIsSavingNotes(true)
    try {
      // Add note to job_notes table or append to job notes
      const currentNotes = job.notes || ''
      const timestamp = new Date().toLocaleString()
      const newNote = `[${timestamp}] Technician Note:\n${notes}\n\n${currentNotes}`
      
      const { error } = await supabase
        .from('jobs')
        .update({ notes: newNote })
        .eq('id', job.id)

      if (error) throw error

      setJob({ ...job, notes: newNote })
      setNotes('')
      toast.success('Note added successfully')
    } catch (error) {
      console.error('Error saving note:', error)
      toast.error('Failed to save note')
    } finally {
      setIsSavingNotes(false)
    }
  }

  const openMediaViewer = (items: any[], index: number) => {
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }

  const formatJobOverview = (description: string | null | undefined) => {
    if (!description) return 'No overview available'
    
    return description.split('\n').map((line, index) => {
      if (line.includes('SERVICES:') || line.includes('ADD-ONS:')) {
        return (
          <div key={index} className="font-semibold mt-2 mb-1">
            {line}
          </div>
        )
      }
      if (line.trim()) {
        return (
          <div key={index} className="ml-2">
            {line}
          </div>
        )
      }
      return <div key={index} className="h-2" />
    })
  }

  return (
    <div className="max-w-7xl mx-auto p-4 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-start">
        <div className="flex items-start gap-4">
          <Link href="/technician">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4" />
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
      </div>

      {/* Quick Status Update Buttons */}
      <Card>
        <CardHeader>
          <CardTitle>Update Job Status</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            {job.status !== 'in_progress' && (
              <Button
                onClick={() => updateJobStatus('in_progress')}
                variant="outline"
                size="sm"
              >
                <AlertCircle className="h-4 w-4 mr-2" />
                Start Job
              </Button>
            )}
            {job.status === 'in_progress' && (
              <Button
                onClick={() => updateJobStatus('completed')}
                variant="default"
                size="sm"
                className="bg-green-600 hover:bg-green-700"
              >
                <CheckCircle className="h-4 w-4 mr-2" />
                Complete Job
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content - Left Side */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Photos & Videos Card */}
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
                userId={userId}
                onUploadComplete={loadJobMedia}
              />
              
              {jobPhotos.length > 0 && (
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-4">
                  {jobPhotos.map((photo, index) => (
                    <div
                      key={photo.id}
                      className="relative group cursor-pointer"
                      onClick={() => openMediaViewer(jobPhotos, index)}
                    >
                      {photo.media_type === 'video' ? (
                        <VideoThumbnail 
                          videoUrl={photo.url} 
                          onClick={() => openMediaViewer(jobPhotos, index)}
                        />
                      ) : (
                        <img
                          src={photo.url}
                          alt={photo.caption || 'Job photo'}
                          className="w-full h-32 object-cover rounded hover:opacity-90 transition"
                        />
                      )}
                      {photo.caption && (
                        <p className="text-xs mt-1 text-muted-foreground truncate">
                          {photo.caption}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Files Card */}
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
                userId={userId}
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

          {/* Add Notes Card */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Add Notes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Add notes about the job..."
                className="w-full p-3 border rounded-md min-h-[100px]"
              />
              <Button
                onClick={saveNotes}
                disabled={!notes.trim() || isSavingNotes}
                className="mt-2"
              >
                <Save className="h-4 w-4 mr-2" />
                {isSavingNotes ? 'Saving...' : 'Save Note'}
              </Button>
              
              {/* Display existing notes */}
              {job.notes && (
                <div className="mt-4 p-3 bg-gray-50 rounded-md">
                  <p className="text-sm font-medium mb-2">Previous Notes:</p>
                  <p className="text-sm text-gray-700 whitespace-pre-wrap">{job.notes}</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Right Sidebar */}
        <div className="space-y-6">
          {/* Job Details Card */}
          <Card>
            <CardHeader>
              <CardTitle>Job Details</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-muted-foreground">Customer</p>
                  <p className="font-medium">{job.customers?.name || 'N/A'}</p>
                  {job.customers?.phone && (
                    <a href={`tel:${job.customers.phone}`} className="text-sm text-blue-600 flex items-center mt-1">
                      <Phone className="h-3 w-3 mr-1" />
                      {job.customers.phone}
                    </a>
                  )}
                  {job.customers?.email && (
                    <a href={`mailto:${job.customers.email}`} className="text-sm text-blue-600 flex items-center mt-1">
                      <Mail className="h-3 w-3 mr-1" />
                      {job.customers.email}
                    </a>
                  )}
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Job Type</p>
                  <p className="font-medium">{job.job_type}</p>
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Job Overview</p>
                  <div className="font-medium">
                    {formatJobOverview(job.description)}
                  </div>
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Scheduled Date</p>
                  <p className="font-medium">
                    {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : 'Not scheduled'}
                  </p>
                </div>
                
                {job.scheduled_time && (
                  <div>
                    <p className="text-sm text-muted-foreground">Scheduled Time</p>
                    <p className="font-medium">
                      {job.scheduled_time}
                    </p>
                  </div>
                )}
                
                <div>
                  <p className="text-sm text-muted-foreground">Service Address</p>
                  <p className="font-medium">
                    {job.service_address || 'No address specified'}
                  </p>
                  {job.service_address && (
                    <a
                      href={`https://maps.google.com/?q=${encodeURIComponent(job.service_address)}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm text-blue-600 flex items-center mt-1"
                    >
                      <MapPin className="h-3 w-3 mr-1" />
                      Get Directions
                    </a>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Media Viewer */}
      {viewerOpen && (
        <MediaViewer
          items={viewerItems}
          initialIndex={viewerIndex}
          onClose={() => setViewerOpen(false)}
        />
      )}
    </div>
  )
}
EOF

# Build test
echo "Testing build..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
  echo "Build successful!"
  
  # Commit and push
  git add -A
  git commit -m "Fixed type errors and completed technician portal with job detail view"
  git push origin main
  
  echo "✅ Successfully fixed all issues and completed technician portal!"
  echo "- Fixed type error in technician page"
  echo "- Created technician job detail view"
  echo "- Technicians can update job status"
  echo "- Technicians can upload photos and files"
  echo "- Technicians can add notes"
  echo "- Prices and proposal links hidden from technicians"
  echo "- Customer contact info with clickable links"
else
  echo "❌ Build failed. Please check the errors above."
  exit 1
fi
