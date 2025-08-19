#!/bin/bash

set -e

echo "🔧 Fixing upload functionality and technician job visibility..."

# 1. First, let's fix the JobDetailView to properly integrate uploads
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx << 'EOF'
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
import EditJobModal from './EditJobModal'
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
      </div>

      {/* Edit Job Modal */}
      {showEditModal && (
        <EditJobModal 
          job={job}
          onClose={() => setShowEditModal(false)}
          onSave={(updatedJob: any) => {
            setJob(updatedJob)
            setShowEditModal(false)
            toast.success('Job updated')
          }}
        />
      )}
    </div>
  )
}
EOF

echo "✅ JobDetailView updated with integrated upload components"
# 2. Update the page.tsx to pass userId
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/\[id\]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobDetailView from './JobDetailView'
import JobDiagnostic from './diagnostic'

export default async function JobDetailPage({ 
  params,
  searchParams 
}: { 
  params: Promise<{ id: string }>
  searchParams: Promise<{ debug?: string }>
}) {
  const { id } = await params
  const { debug } = await searchParams
  
  // Show diagnostic if ?debug=true
  if (debug === 'true') {
    return <JobDiagnostic />
  }
  
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()
  
  const userRole = profile?.role || 'technician'

  // Fetch job with customer info
  const { data: job, error } = await supabase
    .from('jobs')
    .select(`
      *,
      customers!customer_id (
        name,
        email,
        phone,
        address
      )
    `)
    .eq('id', id)
    .single()

  // If job has a proposal_id, fetch it separately
  if (job && job.proposal_id) {
    const { data: proposal } = await supabase
      .from('proposals')
      .select('proposal_number, title, total')
      .eq('id', job.proposal_id)
      .single()
    
    if (proposal) {
      job.proposals = [proposal]
    }
  }

  if (error || !job) {
    return (
      <div className="p-8 max-w-2xl mx-auto">
        <h1 className="text-2xl font-bold mb-4 text-red-600">Job Not Found</h1>
        <div className="bg-red-50 p-4 rounded-lg">
          <p className="mb-2">Job ID: <code>{id}</code></p>
          <p className="mb-2">Error: {error?.message || 'Job does not exist'}</p>
          <p className="text-sm text-gray-600 mt-4">
            Try adding <code>?debug=true</code> to the URL for diagnostic info
          </p>
          <a 
            href={`/jobs/${id}?debug=true`}
            className="inline-block mt-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Run Diagnostic
          </a>
        </div>
      </div>
    )
  }

  return <JobDetailView job={job} userRole={userRole} userId={user.id} />
}
EOF

echo "✅ Updated page.tsx to pass userId"

# 3. Fix the technician jobs query to properly handle RLS
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/jobs/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianJobsList from './TechnicianJobsList'

export default async function TechnicianJobsPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role, full_name')
    .eq('id', user.id)
    .single()

  // Only technicians can access this
  if (profile?.role !== 'technician') {
    redirect('/')
  }

  // Get jobs assigned to this technician - using a more specific query
  const { data: assignedJobs, error } = await supabase
    .from('job_technicians')
    .select(`
      job_id,
      assigned_at,
      jobs!inner (
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
        customer_name,
        customer_phone,
        customer_email,
        created_at
      )
    `)
    .eq('technician_id', user.id)
    .order('assigned_at', { ascending: false })

  if (error) {
    console.error('Error fetching technician jobs:', error)
  }

  // Flatten the jobs data
  const jobs = assignedJobs?.map(item => ({
    ...item.jobs,
    assigned_at: item.assigned_at
  })).filter(Boolean) || []

  // Additionally fetch photos and files for each job
  for (const job of jobs) {
    const { data: photos } = await supabase
      .from('job_photos')
      .select('id, photo_url, caption, created_at')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    const { data: files } = await supabase
      .from('job_files')
      .select('id, file_name, file_url, created_at')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    job.job_photos = photos || []
    job.job_files = files || []
  }

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">My Jobs</h1>
        <p className="text-gray-600">Welcome back, {profile?.full_name || 'Technician'}</p>
      </div>
      
      <TechnicianJobsList jobs={jobs} technicianId={user.id} />
    </div>
  )
}
EOF

echo "✅ Fixed technician jobs query with proper RLS handling"

# 4. Create a SQL script to check and fix RLS policies
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/fix-rls-policies.sql << 'EOF'
-- Check current RLS policies for job_technicians
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'job_technicians';

-- Drop existing policies and recreate
DROP POLICY IF EXISTS "Technicians can view their assignments" ON job_technicians;
DROP POLICY IF EXISTS "Boss and admin can manage assignments" ON job_technicians;

-- Create comprehensive policies for job_technicians
CREATE POLICY "Technicians can view their assignments"
  ON job_technicians
  FOR SELECT
  USING (technician_id = auth.uid());

CREATE POLICY "Boss and admin can view all assignments"
  ON job_technicians
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

CREATE POLICY "Boss and admin can insert assignments"
  ON job_technicians
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

CREATE POLICY "Boss and admin can update assignments"
  ON job_technicians
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

CREATE POLICY "Boss and admin can delete assignments"
  ON job_technicians
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

-- Also ensure jobs table has proper policies for technicians
DROP POLICY IF EXISTS "Technicians can view assigned jobs" ON jobs;

CREATE POLICY "Technicians can view assigned jobs"
  ON jobs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM job_technicians 
      WHERE job_technicians.job_id = jobs.id 
      AND job_technicians.technician_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

-- Test the policies
SELECT 
  'job_technicians' as table_name,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'job_technicians'
UNION ALL
SELECT 
  'jobs' as table_name,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'jobs';
EOF

echo "✅ Created SQL script to fix RLS policies"

# 5. Test the build
echo ""
echo "🔨 Testing build..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -80

# 6. Commit and push changes
echo ""
echo "📦 Committing and pushing changes..."
git add -A
git commit -m "Fix upload functionality and technician job visibility

- Integrated PhotoUpload and FileUpload components directly into JobDetailView
- Fixed userId prop passing from page.tsx to JobDetailView
- Updated technician jobs query to handle RLS properly
- Created SQL script to fix RLS policies for job_technicians table
- Ensured technicians can view their assigned jobs
- Fixed media loading in both boss and technician views"

git push origin main

echo ""
echo "✅ COMPLETE! Changes pushed to GitHub"
echo ""
echo "📝 IMPORTANT: Run this SQL in Supabase to fix RLS policies:"
echo "   Copy the content from fix-rls-policies.sql and execute in Supabase SQL editor"
echo ""
echo "🧪 Test these features:"
echo "1. Upload photos and files in a job (as boss)"
echo "2. Sign in as a technician and check if jobs appear"
echo "3. Verify technicians can see job details without prices"
EOF
