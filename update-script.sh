#!/bin/bash

# Fix UI functionality issues

echo "🔧 Fixing UI functionality issues..."

# 1. Change default view to list and remove send button
echo "📝 Fixing ProposalsList default view and removing send button..."
cat > app/components/proposals/ProposalsList.tsx << 'EOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatCurrency } from '@/lib/utils'
import { FileText, Eye, Edit, Send, CheckCircle, Clock, XCircle, DollarSign, LayoutGrid, List } from 'lucide-react'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

interface Customer {
  id: string
  name: string
  email: string | null
  phone: string | null
}

interface Proposal {
  id: string
  proposal_number: string
  title: string
  status: 'draft' | 'sent' | 'approved' | 'rejected' | 'paid'
  total: number
  created_at: string
  updated_at: string
  customers: Customer
  customer_view_token: string | null
  customer_approved_at: string | null
  customer_signature: string | null
  payment_status: string | null
  deposit_paid_at: string | null
  progress_paid_at: string | null
  final_paid_at: string | null
}

export interface ProposalsListProps {
  proposals: Proposal[]
  userRole: string
}

export default function ProposalsList({ proposals, userRole }: ProposalsListProps) {
  const [proposalsList] = useState(proposals)
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('list') // Changed default to 'list'

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'draft':
        return <FileText className="h-4 w-4" />
      case 'sent':
        return <Send className="h-4 w-4" />
      case 'approved':
        return <CheckCircle className="h-4 w-4" />
      case 'rejected':
        return <XCircle className="h-4 w-4" />
      case 'paid':
        return <DollarSign className="h-4 w-4" />
      default:
        return <Clock className="h-4 w-4" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft':
        return 'bg-gray-100 text-gray-800'
      case 'sent':
        return 'bg-blue-100 text-blue-800'
      case 'approved':
        return 'bg-green-100 text-green-800'
      case 'rejected':
        return 'bg-red-100 text-red-800'
      case 'paid':
        return 'bg-purple-100 text-purple-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getPaymentStatus = (proposal: Proposal) => {
    if (proposal.final_paid_at) return 'Fully Paid'
    if (proposal.progress_paid_at) return 'Progress Payment Received'
    if (proposal.deposit_paid_at) return 'Deposit Received'
    if (proposal.payment_status === 'deposit_paid') return 'Deposit Paid'
    if (proposal.payment_status === 'roughin_paid') return 'Rough-In Paid'
    if (proposal.payment_status === 'paid') return 'Fully Paid'
    return null
  }

  // Sort proposals by updated_at date (most recent first)
  const sortedProposals = [...proposalsList].sort((a, b) => {
    return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
  })

  if (proposalsList.length === 0) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="text-center text-muted-foreground">
            No proposals found. Create your first proposal to get started.
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <>
      {/* View Toggle Buttons */}
      <div className="flex justify-end mb-4">
        <div className="flex gap-2 border rounded-lg p-1">
          <Button
            variant={viewMode === 'grid' ? 'default' : 'ghost'}
            size="sm"
            onClick={() => setViewMode('grid')}
            className="gap-2"
          >
            <LayoutGrid className="h-4 w-4" />
            Box View
          </Button>
          <Button
            variant={viewMode === 'list' ? 'default' : 'ghost'}
            size="sm"
            onClick={() => setViewMode('list')}
            className="gap-2"
          >
            <List className="h-4 w-4" />
            List View
          </Button>
        </div>
      </div>

      {/* Grid View */}
      {viewMode === 'grid' && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {sortedProposals.map((proposal) => {
            const paymentStatus = getPaymentStatus(proposal)
            
            return (
              <Card key={proposal.id}>
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div>
                      <CardTitle className="text-lg">{proposal.title}</CardTitle>
                      <CardDescription>
                        #{proposal.proposal_number} • {proposal.customers?.name || 'No customer'}
                      </CardDescription>
                    </div>
                    <Badge className={getStatusColor(proposal.status)}>
                      <span className="mr-1">{getStatusIcon(proposal.status)}</span>
                      {proposal.status}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-sm text-muted-foreground">Total Amount:</span>
                      <span className="font-semibold">{formatCurrency(proposal.total)}</span>
                    </div>
                    {paymentStatus && (
                      <div className="flex justify-between">
                        <span className="text-sm text-muted-foreground">Payment:</span>
                        <Badge variant="outline" className="text-xs">
                          {paymentStatus}
                        </Badge>
                      </div>
                    )}
                    {proposal.customer_approved_at && (
                      <div className="flex justify-between">
                        <span className="text-sm text-muted-foreground">Approved:</span>
                        <span className="text-sm">
                          {new Date(proposal.customer_approved_at).toLocaleDateString()}
                        </span>
                      </div>
                    )}
                    <div className="flex justify-between">
                      <span className="text-sm text-muted-foreground">Created:</span>
                      <span className="text-sm">
                        {new Date(proposal.created_at).toLocaleDateString()}
                      </span>
                    </div>
                  </div>
                </CardContent>
                <CardFooter className="gap-2">
                  <Link href={`/proposals/${proposal.id}`} className="flex-1">
                    <Button variant="outline" size="sm" className="w-full">
                      <Eye className="h-4 w-4 mr-1" />
                      View
                    </Button>
                  </Link>
                  {(userRole === 'admin' || userRole === 'boss') && proposal.status === 'draft' && (
                    <Link href={`/proposals/${proposal.id}/edit`} className="flex-1">
                      <Button variant="outline" size="sm" className="w-full">
                        <Edit className="h-4 w-4 mr-1" />
                        Edit
                      </Button>
                    </Link>
                  )}
                </CardFooter>
              </Card>
            )
          })}
        </div>
      )}

      {/* List View */}
      {viewMode === 'list' && (
        <Card>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Proposal</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Payment Status</TableHead>
                <TableHead className="text-right">Amount</TableHead>
                <TableHead>Date</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sortedProposals.map((proposal) => {
                const paymentStatus = getPaymentStatus(proposal)
                
                return (
                  <TableRow key={proposal.id}>
                    <TableCell>
                      <Link 
                        href={`/proposals/${proposal.id}`}
                        className="hover:underline"
                      >
                        <div className="font-medium">{proposal.title}</div>
                        <div className="text-sm text-muted-foreground">
                          #{proposal.proposal_number}
                        </div>
                      </Link>
                    </TableCell>
                    <TableCell>{proposal.customers?.name || 'No customer'}</TableCell>
                    <TableCell>
                      <Badge className={getStatusColor(proposal.status)}>
                        <span className="mr-1">{getStatusIcon(proposal.status)}</span>
                        {proposal.status}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {paymentStatus ? (
                        <Badge variant="outline" className="text-xs">
                          {paymentStatus}
                        </Badge>
                      ) : (
                        <span className="text-muted-foreground">-</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right font-semibold">
                      {formatCurrency(proposal.total)}
                    </TableCell>
                    <TableCell>
                      {new Date(proposal.updated_at).toLocaleDateString()}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Link href={`/proposals/${proposal.id}`}>
                          <Button variant="ghost" size="sm">
                            <Eye className="h-4 w-4" />
                          </Button>
                        </Link>
                        {(userRole === 'admin' || userRole === 'boss') && proposal.status === 'draft' && (
                          <Link href={`/proposals/${proposal.id}/edit`}>
                            <Button variant="ghost" size="sm">
                              <Edit className="h-4 w-4" />
                            </Button>
                          </Link>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </Card>
      )}
    </>
  )
}
EOF

# 2. Create SQL to add a technician user
echo "📝 Creating SQL script for technician user..."
cat > create_technician_user.sql << 'EOF'
-- First, you need to create the user in Supabase Auth Dashboard
-- Email: technician@hvac.com
-- Password: asdf
-- Then run this SQL to create the profile:

-- Insert technician profile (update the ID after creating auth user)
INSERT INTO profiles (id, email, full_name, role, phone)
VALUES (
    'YOUR_AUTH_USER_ID_HERE', -- Replace this with the actual auth.users.id after creating the user
    'technician@hvac.com',
    'Test Technician',
    'technician',
    '828-222-3333'
) ON CONFLICT (id) DO UPDATE SET
    full_name = 'Test Technician',
    role = 'technician',
    phone = '828-222-3333';

-- Alternative: If you already created the auth user, find their ID:
-- SELECT id FROM auth.users WHERE email = 'technician@hvac.com';
EOF

# 3. Fix job status update error
echo "📝 Fixing JobDetailView status update..."
# Update the status change function to handle the response properly
sed -i '' 's/const { error } = await supabase/const { data, error } = await supabase/g' app/jobs/[id]/JobDetailView.tsx 2>/dev/null || \
sed -i 's/const { error } = await supabase/const { data, error } = await supabase/g' app/jobs/[id]/JobDetailView.tsx

# 4. Create photo upload component with Google Drive prep
echo "📝 Creating photo upload component..."
cat > app/jobs/[id]/PhotoUpload.tsx << 'EOF'
'use client'

import { useState, useRef } from 'react'
import { Camera, Upload, X, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { createClient } from '@/lib/supabase/client'

interface PhotoUploadProps {
  jobId: string
  userId: string
  onPhotoUploaded?: () => void
}

export default function PhotoUpload({ jobId, userId, onPhotoUploaded }: PhotoUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const [photoType, setPhotoType] = useState<'before' | 'after' | 'during' | 'issue'>('before')
  const fileInputRef = useRef<HTMLInputElement>(null)
  const supabase = createClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    setSelectedFiles(files)
  }

  const handleUpload = async () => {
    if (selectedFiles.length === 0) return

    setIsUploading(true)
    
    try {
      // For now, we'll store photos in Supabase Storage
      // Later, this can be replaced with Google Drive API
      
      for (const file of selectedFiles) {
        // Upload to Supabase Storage
        const fileName = `${jobId}/${Date.now()}-${file.name}`
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('job-photos')
          .upload(fileName, file)

        if (uploadError) {
          console.error('Upload error:', uploadError)
          continue
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('job-photos')
          .getPublicUrl(fileName)

        // Save photo record in database
        const { error: dbError } = await supabase
          .from('job_photos')
          .insert({
            job_id: jobId,
            uploaded_by: userId,
            photo_url: publicUrl,
            photo_type: photoType,
            caption: file.name,
            file_size_bytes: file.size,
            mime_type: file.type
          })

        if (dbError) {
          console.error('Database error:', dbError)
        }
      }

      // Clear selection
      setSelectedFiles([])
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }

      // Notify parent component
      if (onPhotoUploaded) {
        onPhotoUploaded()
      }

      alert('Photos uploaded successfully!')
    } catch (error) {
      console.error('Error uploading photos:', error)
      alert('Failed to upload photos')
    } finally {
      setIsUploading(false)
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Camera className="h-5 w-5" />
          Photo Upload
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Photo Type Selection */}
        <div>
          <label className="text-sm font-medium text-gray-700 mb-2 block">
            Photo Type
          </label>
          <div className="flex gap-2">
            {(['before', 'after', 'during', 'issue'] as const).map((type) => (
              <Button
                key={type}
                variant={photoType === type ? 'default' : 'outline'}
                size="sm"
                onClick={() => setPhotoType(type)}
                type="button"
              >
                {type.charAt(0).toUpperCase() + type.slice(1)}
              </Button>
            ))}
          </div>
        </div>

        {/* File Input */}
        <div>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            multiple
            onChange={handleFileSelect}
            className="hidden"
          />
          <Button
            variant="outline"
            onClick={() => fileInputRef.current?.click()}
            disabled={isUploading}
            className="w-full"
          >
            <Camera className="h-4 w-4 mr-2" />
            Select Photos
          </Button>
        </div>

        {/* Selected Files Preview */}
        {selectedFiles.length > 0 && (
          <div className="space-y-2">
            <p className="text-sm font-medium">Selected Photos:</p>
            {selectedFiles.map((file, index) => (
              <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                <span className="text-sm truncate">{file.name}</span>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSelectedFiles(files => files.filter((_, i) => i !== index))}
                >
                  <X className="h-4 w-4" />
                </Button>
              </div>
            ))}
          </div>
        )}

        {/* Upload Button */}
        {selectedFiles.length > 0 && (
          <Button
            onClick={handleUpload}
            disabled={isUploading}
            className="w-full"
          >
            {isUploading ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Uploading...
              </>
            ) : (
              <>
                <Upload className="h-4 w-4 mr-2" />
                Upload {selectedFiles.length} Photo{selectedFiles.length > 1 ? 's' : ''}
              </>
            )}
          </Button>
        )}

        {/* Google Drive Integration Note */}
        <div className="text-xs text-gray-500 bg-blue-50 p-3 rounded">
          <strong>Note:</strong> Photos are currently stored in Supabase Storage. 
          For Google Drive integration, you'll need:
          <ul className="list-disc list-inside mt-1">
            <li>Google Cloud Console project</li>
            <li>Service Account credentials</li>
            <li>Drive API enabled</li>
            <li>Shared folder permissions</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  )
}
EOF

# 5. Update JobDetailView to include photo upload and fix issues
echo "📝 Updating JobDetailView to fix all issues..."
# Create a complete replacement that fixes the status update and includes photo upload
cat > app/jobs/[id]/JobDetailView_fixed.tsx << 'EOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatDate, formatCurrency } from '@/lib/utils'
import PhotoUpload from './PhotoUpload'
import { 
  ArrowLeft,
  Edit,
  MapPin,
  Phone,
  Mail,
  Calendar,
  Clock,
  Camera,
  Package,
  User,
  FileText
} from 'lucide-react'

interface JobDetailViewProps {
  job: any
  userRole: string
  userId: string
}

export default function JobDetailView({ job, userRole, userId }: JobDetailViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [isUpdating, setIsUpdating] = useState(false)
  const [currentJob, setCurrentJob] = useState(job)
  
  const isBossOrAdmin = userRole === 'boss' || userRole === 'admin'
  const isTechnician = userRole === 'technician'

  const handleStatusChange = async (newStatus: string) => {
    setIsUpdating(true)
    try {
      const { data, error } = await supabase
        .from('jobs')
        .update({ 
          status: newStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', job.id)
        .select()
        .single()

      if (error) {
        console.error('Supabase error:', error)
        throw error
      }

      // Update local state
      setCurrentJob({ ...currentJob, status: newStatus })

      // Log activity
      await supabase
        .from('job_activity_log')
        .insert({
          job_id: job.id,
          user_id: userId,
          activity_type: 'status_change',
          description: `Status changed to ${newStatus}`,
          old_value: job.status,
          new_value: newStatus
        })

      // Refresh the page data
      router.refresh()
    } catch (error: any) {
      console.error('Error updating status:', error)
      alert(`Failed to update status: ${error.message || 'Unknown error'}`)
    } finally {
      setIsUpdating(false)
    }
  }

  const handlePhotoUploaded = () => {
    // Refresh the page to show new photos
    router.refresh()
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      {/* Header */}
      <div className="mb-6">
        <Link
          href="/jobs"
          className="inline-flex items-center text-sm text-gray-600 hover:text-gray-900 mb-4"
        >
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back to Jobs
        </Link>

        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              Job #{currentJob.job_number}
            </h1>
            <p className="mt-1 text-gray-600">{currentJob.title}</p>
          </div>

          <div className="flex items-center gap-2">
            <Badge className="capitalize">
              {currentJob.job_type}
            </Badge>
            {isBossOrAdmin && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => router.push(`/jobs/${job.id}/edit`)}
              >
                <Edit className="h-4 w-4 mr-1" />
                Edit
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Status and Quick Actions */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Job Status</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 mb-4">
            <span className="text-sm text-gray-600">Current Status:</span>
            <Badge className="capitalize">
              {currentJob.status.replace('_', ' ')}
            </Badge>
          </div>
          
          {(isBossOrAdmin || isTechnician) && (
            <div className="flex flex-wrap gap-2">
              {currentJob.status === 'scheduled' && (
                <Button
                  size="sm"
                  onClick={() => handleStatusChange('started')}
                  disabled={isUpdating}
                >
                  Start Job
                </Button>
              )}
              {currentJob.status === 'started' && (
                <Button
                  size="sm"
                  onClick={() => handleStatusChange('in_progress')}
                  disabled={isUpdating}
                >
                  Mark In Progress
                </Button>
              )}
              {currentJob.status === 'in_progress' && (
                <>
                  <Button
                    size="sm"
                    onClick={() => handleStatusChange('rough_in')}
                    disabled={isUpdating}
                  >
                    Complete Rough-In
                  </Button>
                </>
              )}
              {currentJob.status === 'rough_in' && (
                <Button
                  size="sm"
                  onClick={() => handleStatusChange('final')}
                  disabled={isUpdating}
                >
                  Move to Final
                </Button>
              )}
              {currentJob.status === 'final' && (
                <Button
                  size="sm"
                  onClick={() => handleStatusChange('complete')}
                  className="bg-green-600 hover:bg-green-700"
                  disabled={isUpdating}
                >
                  Complete Job
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Rest of the component remains the same... */}
      {/* Customer Information */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Customer Information</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600 mb-1">Name</p>
              <p className="font-medium">{job.customers.name}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600 mb-1">Contact</p>
              <div className="space-y-1">
                {job.customers.phone && (
                  <a href={`tel:${job.customers.phone}`} className="flex items-center gap-2 text-blue-600 hover:underline">
                    <Phone className="h-4 w-4" />
                    {job.customers.phone}
                  </a>
                )}
                {job.customers.email && (
                  <a href={`mailto:${job.customers.email}`} className="flex items-center gap-2 text-blue-600 hover:underline">
                    <Mail className="h-4 w-4" />
                    {job.customers.email}
                  </a>
                )}
              </div>
            </div>
            <div className="md:col-span-2">
              <p className="text-sm text-gray-600 mb-1">Service Address</p>
              <p className="font-medium flex items-center gap-2">
                <MapPin className="h-4 w-4" />
                {job.service_address || job.customers.address || 'No address provided'}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Schedule & Assignment */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Schedule & Assignment</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600 mb-1">Scheduled</p>
              <p className="font-medium flex items-center gap-2">
                <Calendar className="h-4 w-4" />
                {job.scheduled_date ? formatDate(job.scheduled_date) : 'Not scheduled'}
                {job.scheduled_time && ` at ${job.scheduled_time}`}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600 mb-1">Assigned Technician</p>
              <p className="font-medium flex items-center gap-2">
                <User className="h-4 w-4" />
                {job.assigned_technician?.full_name || job.assigned_technician?.email || 'Unassigned'}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Time Tracking */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="h-5 w-5" />
            Time Tracking
          </CardTitle>
        </CardHeader>
        <CardContent>
          {job.job_time_entries?.length > 0 ? (
            <div className="space-y-2">
              {job.job_time_entries.map((entry: any) => (
                <div key={entry.id} className="flex justify-between items-center p-2 bg-gray-50 rounded">
                  <div>
                    <p className="text-sm">
                      {formatDate(entry.clock_in_time)} - 
                      {entry.clock_out_time ? formatDate(entry.clock_out_time) : 'Active'}
                    </p>
                    {entry.is_edited && (
                      <p className="text-xs text-gray-500">Edited: {entry.edit_reason}</p>
                    )}
                  </div>
                  <div>
                    {entry.total_hours && (
                      <Badge variant="outline">{entry.total_hours} hours</Badge>
                    )}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">No time entries yet</p>
          )}
          
          {isTechnician && (
            <Button className="mt-4 w-full" variant="outline">
              <Clock className="h-4 w-4 mr-2" />
              Clock In/Out
            </Button>
          )}
        </CardContent>
      </Card>

      {/* Photo Upload Component */}
      <PhotoUpload 
        jobId={job.id} 
        userId={userId} 
        onPhotoUploaded={handlePhotoUploaded}
      />

      {/* Photos Display */}
      {job.job_photos && job.job_photos.length > 0 && (
        <Card className="mt-6 mb-6">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Camera className="h-5 w-5" />
              Job Photos
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {job.job_photos.map((photo: any) => (
                <div key={photo.id} className="relative">
                  <img
                    src={photo.photo_url}
                    alt={photo.caption || 'Job photo'}
                    className="w-full h-32 object-cover rounded cursor-pointer hover:opacity-90"
                    onClick={() => window.open(photo.photo_url, '_blank')}
                  />
                  <Badge className="absolute top-2 right-2 text-xs">
                    {photo.photo_type}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Materials */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Package className="h-5 w-5" />
            Materials Used
          </CardTitle>
        </CardHeader>
        <CardContent>
          {job.job_materials?.length > 0 ? (
            <div className="space-y-2">
              {job.job_materials.map((material: any) => (
                <div key={material.id} className="flex justify-between items-center p-2 bg-gray-50 rounded">
                  <div>
                    <p className="font-medium">{material.material_name}</p>
                    {material.model_number && (
                      <p className="text-sm text-gray-600">Model: {material.model_number}</p>
                    )}
                    {material.serial_number && (
                      <p className="text-sm text-gray-600">Serial: {material.serial_number}</p>
                    )}
                  </div>
                  <Badge variant="outline">Qty: {material.quantity}</Badge>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">No materials recorded yet</p>
          )}
          
          <Button className="mt-4" variant="outline">
            <Package className="h-4 w-4 mr-2" />
            Add Materials
          </Button>
        </CardContent>
      </Card>

      {/* Notes */}
      {(job.boss_notes || job.completion_notes) && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              Notes
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {job.boss_notes && (
              <div>
                <p className="text-sm font-medium text-gray-600 mb-1">Instructions from Boss</p>
                <p className="whitespace-pre-wrap">{job.boss_notes}</p>
              </div>
            )}
            {job.completion_notes && (
              <div>
                <p className="text-sm font-medium text-gray-600 mb-1">Completion Notes</p>
                <p className="whitespace-pre-wrap">{job.completion_notes}</p>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Linked Proposal */}
      {job.proposals && (
        <Card className="mt-6">
          <CardHeader>
            <CardTitle>Linked Proposal</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex justify-between items-center">
              <div>
                <p className="font-medium">Proposal #{job.proposals.proposal_number}</p>
                <p className="text-sm text-gray-600">
                  Total: {formatCurrency(job.proposals.total)}
                </p>
              </div>
              {isBossOrAdmin && (
                <Link href={`/proposals/${job.proposals.id}`}>
                  <Button variant="outline" size="sm">
                    View Proposal
                  </Button>
                </Link>
              )}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
EOF

# Replace the original with the fixed version
mv app/jobs/[id]/JobDetailView_fixed.tsx app/jobs/[id]/JobDetailView.tsx

# 6. Create Supabase storage bucket for photos
echo "📝 Creating SQL for photo storage bucket..."
cat > create_photo_storage.sql << 'EOF'
-- Create storage bucket for job photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('job-photos', 'job-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
CREATE POLICY "Authenticated users can upload job photos" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'job-photos');

CREATE POLICY "Anyone can view job photos" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'job-photos');

CREATE POLICY "Authenticated users can delete job photos" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'job-photos');
EOF

# Run type check
echo ""
echo "🔍 Running type check..."
npx tsc --noEmit 2>&1 | head -20 || true

# Commit changes
echo ""
echo "📦 Committing fixes..."
git add -A
git commit -m "fix: Multiple UI and functionality improvements

- Changed proposals default view to list
- Removed Send button from proposals list
- Made proposal title clickable to navigate to detail view
- Fixed job status update error handling
- Added photo upload component with Supabase Storage
- Created SQL scripts for technician user creation
- Prepared for Google Drive integration" || echo "No changes to commit"

git push origin main || echo "Failed to push"

echo ""
echo "✅ Fixes complete!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. CREATE TECHNICIAN USER:"
echo "   - Go to Supabase Dashboard > Authentication"
echo "   - Create new user: technician@hvac.com / asdf"
echo "   - Copy the user ID"
echo "   - Run the SQL in create_technician_user.sql with the correct ID"
echo ""
echo "2. CREATE PHOTO STORAGE:"
echo "   - Run create_photo_storage.sql in Supabase SQL editor"
echo ""
echo "3. FOR GOOGLE DRIVE INTEGRATION, you'll need:"
echo "   - Google Cloud Console project"
echo "   - Enable Google Drive API"
echo "   - Create Service Account"
echo "   - Download credentials JSON"
echo "   - Share a Google Drive folder with the service account email"
echo "   - Add credentials to environment variables"
echo ""
echo "The app should now work with photo uploads to Supabase Storage!"