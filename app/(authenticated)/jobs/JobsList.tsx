'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { MapPin, Phone, Mail, Calendar, DollarSign, FileText, Users } from 'lucide-react'

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
    switch (status) {
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'in_progress': return 'bg-blue-100 text-blue-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
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
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Address</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Value</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Status</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Tasks</th>
                    <th className="px-4 py-3 text-left text-sm font-medium text-gray-700">Created</th>
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
                          <p className="font-medium">{job.customer_name}</p>
                          {job.customer_email && (
                            <p className="text-sm text-gray-500">{job.customer_email}</p>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <p className="text-sm">{job.service_address}</p>
                        {job.service_city && (
                          <p className="text-sm text-gray-500">
                            {job.service_city}, {job.service_state} {job.service_zip}
                          </p>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        {formatCurrency(job.total_value)}
                      </td>
                      <td className="px-4 py-3">
                        <Badge className={getStatusColor(job.status)}>
                          {job.status.replace('_', ' ')}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-sm">
                          {job.tasks?.[0]?.count || 0} tasks
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-500">
                        {formatDate(job.created_at)}
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
              <CardHeader>
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle className="text-lg">{job.job_number}</CardTitle>
                    <Badge className={`mt-2 ${getStatusColor(job.status)}`}>
                      {job.status.replace('_', ' ')}
                    </Badge>
                  </div>
                  <span className="text-lg font-bold text-green-600">
                    {formatCurrency(job.total_value)}
                  </span>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div>
                  <p className="font-medium">{job.customer_name}</p>
                  {job.customer_email && (
                    <p className="text-sm text-gray-500 flex items-center mt-1">
                      <Mail className="h-3 w-3 mr-1" />
                      {job.customer_email}
                    </p>
                  )}
                  {job.customer_phone && (
                    <p className="text-sm text-gray-500 flex items-center mt-1">
                      <Phone className="h-3 w-3 mr-1" />
                      {job.customer_phone}
                    </p>
                  )}
                </div>

                {job.service_address && (
                  <div className="text-sm text-gray-600">
                    <p className="flex items-start">
                      <MapPin className="h-3 w-3 mr-1 mt-0.5" />
                      <span>
                        {job.service_address}
                        {job.service_city && (
                          <>, {job.service_city}, {job.service_state} {job.service_zip}</>
                        )}
                      </span>
                    </p>
                  </div>
                )}

                <div className="flex items-center justify-between text-sm">
                  <span className="flex items-center text-gray-500">
                    <Users className="h-3 w-3 mr-1" />
                    {job.tasks?.[0]?.count || 0} tasks
                  </span>
                  <span className="flex items-center text-gray-500">
                    <Calendar className="h-3 w-3 mr-1" />
                    {formatDate(job.created_at)}
                  </span>
                </div>

                {job.job_proposals?.length > 0 && (
                  <div className="pt-2 border-t">
                    <p className="text-xs text-gray-500 mb-1">Linked Proposals:</p>
                    {job.job_proposals.map((jp: any) => (
                      <Badge key={jp.proposal_id} variant="outline" className="text-xs mr-1">
                        #{jp.proposals?.proposal_number}
                      </Badge>
                    ))}
                  </div>
                )}

                <Link href={`/jobs/${job.id}`} className="block">
                  <Button className="w-full" variant="outline">
                    View Details
                  </Button>
                </Link>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
