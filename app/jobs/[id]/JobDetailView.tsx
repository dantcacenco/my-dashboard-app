import type { Job, Customer, Profile, Proposal } from '@/app/types'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatDate, formatCurrency } from '@/lib/utils'
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
  
  const isBossOrAdmin = userRole === 'boss' || userRole === 'admin'
  const isTechnician = userRole === 'technician'

  const handleStatusChange = async (newStatus: string) => {
    try {
      const { error } = await supabase
        .from('jobs')
        .update({ status: newStatus })
        .eq('id', job.id)

      if (error) throw error

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

      router.refresh()
    } catch (error: any) {
      console.error('Error updating status:', error)
      alert('Failed to update status')
    }
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
              Job #{job.job_number}
            </h1>
            <p className="mt-1 text-gray-600">{job.title}</p>
          </div>

          <div className="flex items-center gap-2">
            <Badge className="capitalize">
              {job.job_type}
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
              {job.status.replace('_', ' ')}
            </Badge>
          </div>
          
          {(isBossOrAdmin || isTechnician) && (
            <div className="flex flex-wrap gap-2">
              {job.status === 'scheduled' && (
                <Button
                  size="sm"
                  onClick={() => handleStatusChange('started')}
                >
                  Start Job
                </Button>
              )}
              {job.status === 'started' && (
                <Button
                  size="sm"
                  onClick={() => handleStatusChange('in_progress')}
                >
                  Mark In Progress
                </Button>
              )}
              {job.status === 'in_progress' && (
                <>
                  <Button
                    size="sm"
                    onClick={() => handleStatusChange('rough_in')}
                  >
                    Complete Rough-In
                  </Button>
                </>
              )}
              {job.status === 'rough_in' && (
                <Button
                  size="sm"
                  onClick={() => handleStatusChange('final')}
                >
                  Move to Final
                </Button>
              )}
              {job.status === 'final' && (
                <Button
                  size="sm"
                  onClick={() => handleStatusChange('complete')}
                  className="bg-green-600 hover:bg-green-700"
                >
                  Complete Job
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>

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

      {/* Photos */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Camera className="h-5 w-5" />
            Photos
          </CardTitle>
        </CardHeader>
        <CardContent>
          {job.job_photos?.length > 0 ? (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {job.job_photos.map((photo: any) => (
                <div key={photo.id} className="relative">
                  <img
                    src={photo.photo_url}
                    alt={photo.caption || 'Job photo'}
                    className="w-full h-32 object-cover rounded"
                  />
                  <Badge className="absolute top-2 right-2 text-xs">
                    {photo.photo_type}
                  </Badge>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-500">No photos uploaded yet</p>
          )}
          
          <Button className="mt-4" variant="outline">
            <Camera className="h-4 w-4 mr-2" />
            Upload Photos
          </Button>
        </CardContent>
      </Card>

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
