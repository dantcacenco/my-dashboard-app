'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatDate } from '@/lib/utils'
import { 
  Eye, 
  MapPin, 
  Calendar,
  User,
  Briefcase,
  AlertCircle,
  CheckCircle,
  Clock,
  Wrench
} from 'lucide-react'

interface Job {
  id: string
  job_number: string
  title: string
  job_type: string
  status: string
  scheduled_date: string | null
  scheduled_time: string | null
  customers: {
    id: string
    name: string
    address: string | null
  }
  assigned_technician: {
    id: string
    full_name: string | null
    email: string
  } | null
}

interface JobsListProps {
  jobs: Job[]
  userRole: string
  userId: string
}

export default function JobsList({ jobs, userRole, userId }: JobsListProps) {
  const [filter, setFilter] = useState<string>('all')

  const getJobTypeIcon = (type: string) => {
    switch (type) {
      case 'installation':
        return <Briefcase className="h-4 w-4" />
      case 'repair':
        return <Wrench className="h-4 w-4" />
      case 'maintenance':
        return <CheckCircle className="h-4 w-4" />
      case 'emergency':
        return <AlertCircle className="h-4 w-4" />
      default:
        return <Clock className="h-4 w-4" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled':
        return 'bg-blue-100 text-blue-800'
      case 'started':
        return 'bg-yellow-100 text-yellow-800'
      case 'in_progress':
        return 'bg-orange-100 text-orange-800'
      case 'rough_in':
        return 'bg-purple-100 text-purple-800'
      case 'final':
        return 'bg-indigo-100 text-indigo-800'
      case 'complete':
        return 'bg-green-100 text-green-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const filteredJobs = filter === 'all' 
    ? jobs 
    : jobs.filter(job => job.status === filter)

  if (jobs.length === 0) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="text-center text-muted-foreground">
            {userRole === 'technician' 
              ? 'No jobs assigned to you yet.'
              : 'No jobs found. Create your first job to get started.'}
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <>
      {/* Filter buttons */}
      <div className="mb-4 flex gap-2">
        <Button
          variant={filter === 'all' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setFilter('all')}
        >
          All Jobs ({jobs.length})
        </Button>
        <Button
          variant={filter === 'scheduled' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setFilter('scheduled')}
        >
          Scheduled
        </Button>
        <Button
          variant={filter === 'in_progress' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setFilter('in_progress')}
        >
          In Progress
        </Button>
        <Button
          variant={filter === 'complete' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setFilter('complete')}
        >
          Complete
        </Button>
      </div>

      {/* Jobs grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {filteredJobs.map((job) => (
          <Card key={job.id}>
            <CardHeader>
              <div className="flex justify-between items-start">
                <div>
                  <CardTitle className="text-lg flex items-center gap-2">
                    {getJobTypeIcon(job.job_type)}
                    {job.title}
                  </CardTitle>
                  <CardDescription>
                    #{job.job_number} • {job.customers?.name || 'No customer'}
                  </CardDescription>
                </div>
                <Badge className={getStatusColor(job.status)}>
                  {job.status.replace('_', ' ')}
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-sm">
                {job.scheduled_date && (
                  <div className="flex items-center gap-2 text-gray-600">
                    <Calendar className="h-4 w-4" />
                    {formatDate(job.scheduled_date)}
                    {job.scheduled_time && ` at ${job.scheduled_time}`}
                  </div>
                )}
                {job.customers?.address && (
                  <div className="flex items-center gap-2 text-gray-600">
                    <MapPin className="h-4 w-4" />
                    {job.customers.address}
                  </div>
                )}
                {job.assigned_technician && (
                  <div className="flex items-center gap-2 text-gray-600">
                    <User className="h-4 w-4" />
                    {job.assigned_technician.full_name || job.assigned_technician.email}
                  </div>
                )}
              </div>
            </CardContent>
            <CardFooter>
              <Link href={`/jobs/${job.id}`} className="w-full">
                <Button variant="outline" size="sm" className="w-full">
                  <Eye className="h-4 w-4 mr-1" />
                  View Details
                </Button>
              </Link>
            </CardFooter>
          </Card>
        ))}
      </div>
    </>
  )
}
