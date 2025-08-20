'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Calendar, MapPin, Phone, Mail, FileText, Camera, ChevronRight, Clock } from 'lucide-react'

interface TechnicianJobsListProps {
  jobs: any[]
  technicianId: string
}

export default function TechnicianJobsList({ jobs, technicianId }: TechnicianJobsListProps) {
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
        <Link 
          key={job.id} 
          href={`/technician/jobs/${job.id}`}
          className="block"
        >
          <div className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow cursor-pointer">
            <div className="p-4">
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
                      {job.scheduled_time && (
                        <>
                          <Clock className="h-4 w-4 ml-2" />
                          {formatTime(job.scheduled_time)}
                        </>
                      )}
                    </div>
                    
                    <div className="flex items-center gap-2">
                      <MapPin className="h-4 w-4" />
                      {job.service_address || 'No address specified'}
                    </div>
                    
                    {job.customer_name && (
                      <div className="flex items-center gap-2">
                        <span className="text-gray-500">Customer:</span>
                        <span className="font-medium">{job.customer_name}</span>
                      </div>
                    )}
                    
                    <div className="flex items-center gap-2">
                      <span className="text-gray-500">Job #{job.job_number}</span>
                    </div>
                  </div>
                  
                  {job.description && (
                    <p className="text-sm text-gray-600 mt-2 line-clamp-2">
                      {job.description}
                    </p>
                  )}
                </div>
                
                <div className="ml-4">
                  <ChevronRight className="h-5 w-5 text-gray-400" />
                </div>
              </div>
            </div>
          </div>
        </Link>
      ))}
    </div>
  )
}
