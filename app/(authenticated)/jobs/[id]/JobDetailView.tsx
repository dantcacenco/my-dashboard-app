'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  MapPin, Phone, Mail, Calendar, DollarSign, 
  FileText, Plus, Clock, User, Edit
} from 'lucide-react'
import Link from 'next/link'

interface JobDetailViewProps {
  job: any
  userRole: string
  userId: string
}

export default function JobDetailView({ job, userRole, userId }: JobDetailViewProps) {
  const router = useRouter()
  const [showTaskForm, setShowTaskForm] = useState(false)

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'in_progress': return 'bg-blue-100 text-blue-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getTaskStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled': return 'bg-gray-100 text-gray-800'
      case 'in_progress': return 'bg-blue-100 text-blue-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold">Job {job.job_number}</h1>
          <Badge className={`mt-2 ${getStatusColor(job.status)}`}>
            {job.status.replace('_', ' ')}
          </Badge>
        </div>
        <div className="flex gap-2">
          {(userRole === 'boss' || userRole === 'admin') && (
            <>
              <Button variant="outline" size="sm">
                <Edit className="h-4 w-4 mr-1" />
                Edit Job
              </Button>
              <Button size="sm" onClick={() => setShowTaskForm(true)}>
                <Plus className="h-4 w-4 mr-1" />
                Create Task
              </Button>
            </>
          )}
        </div>
      </div>

      {/* Job Details */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Customer Information */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Customer Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <p className="font-medium text-lg">{job.customer_name}</p>
            </div>
            {job.customer_email && (
              <div className="flex items-center text-sm">
                <Mail className="h-4 w-4 mr-2 text-gray-400" />
                <a href={`mailto:${job.customer_email}`} className="text-blue-600 hover:text-blue-700">
                  {job.customer_email}
                </a>
              </div>
            )}
            {job.customer_phone && (
              <div className="flex items-center text-sm">
                <Phone className="h-4 w-4 mr-2 text-gray-400" />
                <a href={`tel:${job.customer_phone}`} className="text-blue-600 hover:text-blue-700">
                  {job.customer_phone}
                </a>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Service Location */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Service Location</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-start">
              <MapPin className="h-4 w-4 mr-2 text-gray-400 mt-0.5" />
              <div className="text-sm">
                <p>{job.service_address}</p>
                {job.service_city && (
                  <p>{job.service_city}, {job.service_state} {job.service_zip}</p>
                )}
              </div>
            </div>
            {job.service_address && (
              <Button 
                variant="outline" 
                size="sm" 
                className="w-full mt-3"
                onClick={() => window.open(`https://maps.google.com/?q=${encodeURIComponent(job.service_address + ' ' + (job.service_city || '') + ' ' + (job.service_state || '') + ' ' + (job.service_zip || ''))}`, '_blank')}
              >
                <MapPin className="h-4 w-4 mr-1" />
                View on Map
              </Button>
            )}
          </CardContent>
        </Card>

        {/* Job Value */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Job Value</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold text-green-600">
              {formatCurrency(job.total_value)}
            </p>
            <p className="text-sm text-gray-500 mt-2">
              Created on {formatDate(job.created_at)}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Linked Proposals */}
      {job.job_proposals && job.job_proposals.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Linked Proposals</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {job.job_proposals.map((jp: any) => (
                <div key={jp.proposal_id} className="flex items-center justify-between border-b pb-2 last:border-0">
                  <div>
                    <Link 
                      href={`/proposals/${jp.proposal_id}`}
                      className="font-medium text-blue-600 hover:text-blue-700"
                    >
                      Proposal #{jp.proposals?.proposal_number}
                    </Link>
                    <p className="text-sm text-gray-600">{jp.proposals?.title}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium">{formatCurrency(jp.proposals?.total || 0)}</p>
                    <Badge className="text-xs">
                      {jp.proposals?.status}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Tasks */}
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <CardTitle className="text-lg">Tasks</CardTitle>
            <span className="text-sm text-gray-500">
              {job.tasks?.length || 0} total tasks
            </span>
          </div>
        </CardHeader>
        <CardContent>
          {job.tasks && job.tasks.length > 0 ? (
            <div className="space-y-3">
              {job.tasks.map((task: any) => (
                <div key={task.id} className="border rounded-lg p-4 hover:shadow-sm">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h4 className="font-medium">{task.title}</h4>
                        <Badge className={`text-xs ${getTaskStatusColor(task.status)}`}>
                          {task.status}
                        </Badge>
                      </div>
                      <div className="mt-2 space-y-1 text-sm text-gray-600">
                        <div className="flex items-center">
                          <Calendar className="h-3 w-3 mr-1" />
                          {formatDate(task.scheduled_date)}
                          {task.scheduled_start_time && (
                            <span className="ml-2">
                              <Clock className="inline h-3 w-3 mr-1" />
                              {task.scheduled_start_time}
                            </span>
                          )}
                        </div>
                        {task.task_technicians && task.task_technicians.length > 0 && (
                          <div className="flex items-center">
                            <User className="h-3 w-3 mr-1" />
                            {task.task_technicians.map((tt: any) => 
                              tt.profiles?.full_name
                            ).filter(Boolean).join(', ')}
                          </div>
                        )}
                      </div>
                    </div>
                    <Link href={`/tasks/${task.id}`}>
                      <Button variant="outline" size="sm">
                        View
                      </Button>
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-center text-gray-500 py-8">
              No tasks created yet
            </p>
          )}
        </CardContent>
      </Card>

      {/* Notes */}
      {job.notes && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Notes</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-gray-700 whitespace-pre-wrap">{job.notes}</p>
          </CardContent>
        </Card>
      )}

      {/* House Plans */}
      {job.house_plan_pdf_url && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">House Plans</CardTitle>
          </CardHeader>
          <CardContent>
            <a 
              href={job.house_plan_pdf_url} 
              target="_blank" 
              rel="noopener noreferrer"
              className="flex items-center text-blue-600 hover:text-blue-700"
            >
              <FileText className="h-4 w-4 mr-2" />
              View House Plans PDF
            </a>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
