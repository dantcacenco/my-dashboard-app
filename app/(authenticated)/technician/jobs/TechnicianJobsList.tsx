'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Calendar, MapPin, Phone, Mail, FileText, Camera, ChevronDown, ChevronUp } from 'lucide-react'

interface TechnicianJobsListProps {
  jobs: any[]
  technicianId: string
}

export default function TechnicianJobsList({ jobs, technicianId }: TechnicianJobsListProps) {
  const [expandedJob, setExpandedJob] = useState<string | null>(null)

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled': return 'bg-blue-100 text-blue-800'
      case 'in_progress': return 'bg-yellow-100 text-yellow-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const formatTime = (time: string) => {
    if (!time) return 'Not set'
    try {
      const [hours, minutes] = time.split(':')
      const hour = parseInt(hours)
      const ampm = hour >= 12 ? 'PM' : 'AM'
      const displayHour = hour % 12 || 12
      return `${displayHour}:${minutes} ${ampm}`
    } catch {
      return time
    }
  }

  if (jobs.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow p-8 text-center">
        <p className="text-gray-500">No jobs assigned to you yet.</p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {jobs.map((job) => (
        <div key={job.id} className="bg-white rounded-lg shadow overflow-hidden">
          {/* Job Header */}
          <div
            className="p-4 cursor-pointer hover:bg-gray-50"
            onClick={() => setExpandedJob(expandedJob === job.id ? null : job.id)}
          >
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <h3 className="font-semibold text-lg">{job.title}</h3>
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(job.status)}`}>
                    {job.status.replace('_', ' ').toUpperCase()}
                  </span>
                </div>
                
                <div className="text-sm text-gray-600 space-y-1">
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4" />
                    {job.scheduled_date ? formatDate(job.scheduled_date) : 'Not scheduled'}
                    {job.scheduled_time && ` at ${formatTime(job.scheduled_time)}`}
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <MapPin className="h-4 w-4" />
                    {job.service_address || 'No address specified'}
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <span className="text-gray-500">Job #{job.job_number}</span>
                  </div>
                </div>
              </div>
              
              <div>
                {expandedJob === job.id ? (
                  <ChevronUp className="h-5 w-5 text-gray-400" />
                ) : (
                  <ChevronDown className="h-5 w-5 text-gray-400" />
                )}
              </div>
            </div>
          </div>

          {/* Expanded Content */}
          {expandedJob === job.id && (
            <div className="border-t px-4 py-4 space-y-4">
              {/* Customer Info */}
              <div>
                <h4 className="font-medium mb-2">Customer Information</h4>
                <div className="bg-gray-50 rounded p-3 space-y-2 text-sm">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">Name:</span> {job.customer_name}
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone className="h-4 w-4" />
                    <a href={`tel:${job.customer_phone}`} className="text-blue-600 hover:underline">
                      {job.customer_phone}
                    </a>
                  </div>
                  <div className="flex items-center gap-2">
                    <Mail className="h-4 w-4" />
                    <a href={`mailto:${job.customer_email}`} className="text-blue-600 hover:underline">
                      {job.customer_email}
                    </a>
                  </div>
                </div>
              </div>

              {/* Job Details */}
              {job.description && (
                <div>
                  <h4 className="font-medium mb-2">Job Description</h4>
                  <div className="bg-gray-50 rounded p-3">
                    <p className="text-sm whitespace-pre-wrap">{job.description}</p>
                  </div>
                </div>
              )}

              {/* Notes */}
              {job.notes && (
                <div>
                  <h4 className="font-medium mb-2">Notes</h4>
                  <div className="bg-yellow-50 rounded p-3">
                    <p className="text-sm whitespace-pre-wrap">{job.notes}</p>
                  </div>
                </div>
              )}

              {/* Photos */}
              {job.job_photos && job.job_photos.length > 0 && (
                <div>
                  <h4 className="font-medium mb-2 flex items-center gap-2">
                    <Camera className="h-4 w-4" />
                    Photos ({job.job_photos.length})
                  </h4>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                    {job.job_photos.map((photo: any) => (
                      <a
                        key={photo.id}
                        href={photo.photo_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="block aspect-square bg-gray-100 rounded overflow-hidden hover:opacity-75"
                      >
                        <img
                          src={photo.photo_url}
                          alt={photo.caption || 'Job photo'}
                          className="w-full h-full object-cover"
                        />
                      </a>
                    ))}
                  </div>
                </div>
              )}

              {/* Files */}
              {job.job_files && job.job_files.length > 0 && (
                <div>
                  <h4 className="font-medium mb-2 flex items-center gap-2">
                    <FileText className="h-4 w-4" />
                    Files ({job.job_files.length})
                  </h4>
                  <div className="space-y-1">
                    {job.job_files.map((file: any) => (
                      <a
                        key={file.id}
                        href={file.file_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-2 p-2 bg-gray-50 rounded hover:bg-gray-100"
                      >
                        <FileText className="h-4 w-4 text-gray-500" />
                        <span className="text-sm text-blue-600 hover:underline">
                          {file.file_name}
                        </span>
                      </a>
                    ))}
                  </div>
                </div>
              )}

              {/* Actions */}
              <div className="flex gap-2 pt-2">
                <Link
                  href={`/technician/jobs/${job.id}`}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  View Full Details
                </Link>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  )
}
