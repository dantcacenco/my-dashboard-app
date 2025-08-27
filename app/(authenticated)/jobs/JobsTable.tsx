'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ChevronLeft, ChevronRight, Eye } from 'lucide-react'

interface JobsTableProps {
  jobs: any[]
  totalCount: number
  currentPage: number
  pageSize: number
}

export default function JobsTable({ 
  jobs, 
  totalCount, 
  currentPage, 
  pageSize 
}: JobsTableProps) {
  const router = useRouter()
  const totalPages = Math.ceil(totalCount / pageSize)

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

  const handleRowClick = (jobId: string) => {
    console.log('Navigating to job:', jobId)
    router.push(`/jobs/${jobId}`)
  }

  return (
    <div>
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Job Number</TableHead>
              <TableHead>Customer</TableHead>
              <TableHead>Title</TableHead>
              <TableHead>Type</TableHead>
              <TableHead>Scheduled</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Technician</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {jobs.map((job) => (
              <TableRow 
                key={job.id}
                className="cursor-pointer hover:bg-muted/50"
                onClick={() => handleRowClick(job.id)}
              >
                <TableCell className="font-medium">{job.job_number}</TableCell>
                <TableCell>{job.customers?.name || 'N/A'}</TableCell>
                <TableCell>{job.title || 'Untitled'}</TableCell>
                <TableCell className="capitalize">{job.job_type || 'N/A'}</TableCell>
                <TableCell>
                  {job.scheduled_date 
                    ? new Date(job.scheduled_date).toLocaleDateString() 
                    : 'Not scheduled'}
                </TableCell>
                <TableCell>
                  <Badge className={`${getStatusColor(job.status)} text-white`}>
                    {job.status?.replace('_', ' ').toUpperCase()}
                  </Badge>
                </TableCell>
                <TableCell>
                  {job.profiles?.full_name || 'Unassigned'}
                </TableCell>
                <TableCell>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={(e) => {
                      e.stopPropagation()
                      router.push(`/jobs/${job.id}`)
                    }}
                  >
                    <Eye className="h-4 w-4" />
                  </Button>
                </TableCell>
              </TableRow>
            ))}
            {jobs.length === 0 && (
              <TableRow>
                <TableCell colSpan={8} className="text-center text-muted-foreground">
                  No jobs found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-muted-foreground">
            Showing {((currentPage - 1) * pageSize) + 1} to {Math.min(currentPage * pageSize, totalCount)} of {totalCount} jobs
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => router.push(`/jobs?page=${currentPage - 1}`)}
              disabled={currentPage === 1}
            >
              <ChevronLeft className="h-4 w-4" />
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => router.push(`/jobs?page=${currentPage + 1}`)}
              disabled={currentPage === totalPages}
            >
              Next
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
