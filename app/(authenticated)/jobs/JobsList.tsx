'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { MapPin, Phone, Mail, Calendar, DollarSign, Users } from 'lucide-react'
import { getUnifiedDisplayStatus } from '@/lib/status-sync'

interface JobsListProps {
  jobs: any[]
  userRole: string
}

export default function JobsList({ jobs, userRole }: JobsListProps) {
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('list')

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
    // Normalize the display status for color matching
    const normalizedStatus = status.toLowerCase().replace(' ', '_').replace('-', '_')
    
    switch (normalizedStatus) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'approved': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      case 'deposit_paid': return 'bg-blue-100 text-blue-800'
      case 'rough_in_paid': return 'bg-yellow-100 text-yellow-800'
      case 'final_payment_complete': return 'bg-green-100 text-green-800'
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'scheduled': return 'bg-blue-100 text-blue-800'
      case 'in_progress': return 'bg-purple-100 text-purple-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      case 'not_scheduled': return 'bg-gray-100 text-gray-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  if (jobs.length === 0) {
    return (
      <Card>
        <CardContent className="text-center py-12">
          <p className="text-gray-500">No jobs found</p>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-4">
      {/* View Toggle */}
      <div className="flex justify-end">
        <div className="flex gap-2">
          <Button
            variant={viewMode === 'list' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('list')}
          >
            List View
          </Button>
          <Button
            variant={viewMode === 'grid' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('grid')}
          >
            Grid View
          </Button>
        </div>
      </div>

      {viewMode === 'list' ? (
        <Card>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 border-b">
                  <tr>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Job #</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Customer</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Title</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Address</th>
                    {userRole !== 'technician' && (
                      <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Value</th>
                    )}
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Status</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Scheduled</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {jobs.map((job) => (
                    <tr key={job.id} className="hover:bg-gray-50">
                      <td className="px-4 py-3">
                        <Link href={`/jobs/${job.id}`} className="font-medium text-blue-600 hover:text-blue-700">
                          {job.job_number}
                        </Link>
                      </td>
                      <td className="px-4 py-3">
                        <div>
                          <div className="font-medium">{job.customer_name || job.customers?.name || 'N/A'}</div>
                          <div className="text-sm text-gray-500">{job.customer_phone || job.customers?.phone}</div>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="max-w-xs truncate">{job.title}</div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="text-sm">{job.service_address || 'No address'}</div>
                      </td>
                      {userRole !== 'technician' && (
                        <td className="px-4 py-3">
                          {job.total_value ? formatCurrency(job.total_value) : '-'}
                        </td>
                      )}
                      <td className="px-4 py-3">
                        {(() => {
                          const displayStatus = getUnifiedDisplayStatus(
                            job.status, 
                            job.proposals?.status || ''
                          )
                          return (
                            <Badge className={getStatusColor(displayStatus)}>
                              {displayStatus}
                            </Badge>
                          )
                        })()}
                      </td>
                      <td className="px-4 py-3">
                        {job.scheduled_date ? formatDate(job.scheduled_date) : 'Not scheduled'}
                      </td>
                      <td className="px-4 py-3">
                        <Link href={`/jobs/${job.id}`}>
                          <Button size="sm" variant="outline">
                            View
                          </Button>
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {jobs.map((job) => (
            <Card key={job.id} className="hover:shadow-lg transition-shadow">
              <CardContent className="p-4">
                <div className="flex justify-between items-start mb-3">
                  <div>
                    <Link href={`/jobs/${job.id}`} className="font-semibold text-blue-600 hover:text-blue-700">
                      {job.job_number}
                    </Link>
                    {(() => {
                      const displayStatus = getUnifiedDisplayStatus(
                        job.status, 
                        job.proposals?.status || ''
                      )
                      return (
                        <Badge className={`ml-2 ${getStatusColor(displayStatus)}`}>
                          {displayStatus}
                        </Badge>
                      )
                    })()}
                  </div>
                </div>
                
                <h3 className="font-medium mb-2">{job.title}</h3>
                
                <div className="space-y-1 text-sm text-gray-600">
                  <div className="flex items-center gap-2">
                    <Users className="h-4 w-4" />
                    {job.customer_name || job.customers?.name || 'N/A'}
                  </div>
                  
                  {job.service_address && (
                    <div className="flex items-center gap-2">
                      <MapPin className="h-4 w-4" />
                      {job.service_address}
                    </div>
                  )}
                  
                  {job.scheduled_date && (
                    <div className="flex items-center gap-2">
                      <Calendar className="h-4 w-4" />
                      {formatDate(job.scheduled_date)}
                    </div>
                  )}
                  
                  {userRole !== 'technician' && job.total_value && (
                    <div className="flex items-center gap-2">
                      <DollarSign className="h-4 w-4" />
                      {formatCurrency(job.total_value)}
                    </div>
                  )}
                </div>
                
                <div className="mt-4">
                  <Link href={`/jobs/${job.id}`}>
                    <Button className="w-full" size="sm">
                      View Details
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
