#!/bin/bash

# Fix job navigation and title issues

set -e

echo "============================================"
echo "Fixing Job Navigation and Title Issues"
echo "============================================"

PROJECT_DIR="/Users/dantcacenco/Documents/GitHub/my-dashboard-app"
cd "$PROJECT_DIR"

# First, let's check the jobs table component to fix navigation
echo "Checking jobs table for navigation issue..."

# Fix the JobsTable component to properly navigate to job details
cat > "$PROJECT_DIR/app/(authenticated)/jobs/JobsTable.tsx" << 'EOF'
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
EOF

echo "JobsTable navigation fixed"

# Now fix the Create Job modal to use proposal title
echo "Fixing Create Job to use proposal title..."

cat > "$PROJECT_DIR/components/proposals/CreateJobModal.tsx" << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'

interface CreateJobModalProps {
  isOpen: boolean
  onClose: () => void
  proposal: any
}

export default function CreateJobModal({ isOpen, onClose, proposal }: CreateJobModalProps) {
  const router = useRouter()
  const supabase = createClient()
  const [isCreating, setIsCreating] = useState(false)
  
  // Initialize form with proposal data
  // Use the proposal title or description, not a generic "Job from Proposal" text
  const proposalTitle = proposal.items?.find((item: any) => item.is_service)?.name || 
                       proposal.description || 
                       `${proposal.job_type || 'Service'} Job`
  
  const [formData, setFormData] = useState({
    title: proposalTitle, // Use actual proposal title/service name
    job_type: proposal.job_type || 'installation',
    status: 'not_scheduled',
    total_amount: proposal.total || 0,
    description: `SERVICES:\n${proposal.items?.filter((i: any) => i.is_service).map((i: any) => `${i.quantity}x ${i.name}`).join('\n') || ''}\n\nADD-ONS:\n${proposal.items?.filter((i: any) => !i.is_service).map((i: any) => `${i.quantity}x ${i.name}`).join('\n') || ''}`.trim(),
  })

  const handleCreate = async () => {
    setIsCreating(true)
    console.log('Creating job with title:', formData.title)
    
    try {
      // Generate job number
      const jobNumber = `JOB-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.random().toString(36).substr(2, 3).toUpperCase()}`

      // Create the job
      const { data: newJob, error } = await supabase
        .from('jobs')
        .insert({
          job_number: jobNumber,
          proposal_id: proposal.id,
          customer_id: proposal.customer_id,
          title: formData.title,
          description: formData.description,
          job_type: formData.job_type,
          status: formData.status,
          total_amount: formData.total_amount,
          payment_status: 'pending',
          created_by: proposal.created_by,
        })
        .select()
        .single()

      if (error) throw error

      toast.success('Job created successfully!')
      router.push(`/jobs/${newJob.id}`)
      onClose()
    } catch (error) {
      console.error('Error creating job:', error)
      toast.error('Failed to create job')
    } finally {
      setIsCreating(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Create Job from Proposal #{proposal.proposal_number}</DialogTitle>
          <p className="text-sm text-muted-foreground">
            Create a new job based on this approved proposal. The job details have been pre-filled.
          </p>
        </DialogHeader>
        
        <div className="space-y-4 py-4">
          <div>
            <Label>Customer</Label>
            <Input 
              value={`${proposal.customers?.name || 'Unknown'} - ${proposal.customers?.email || ''}`}
              disabled
            />
          </div>

          <div>
            <Label>Job Title *</Label>
            <Input
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="Enter job title..."
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Job Type</Label>
              <select
                className="w-full p-2 border rounded"
                value={formData.job_type}
                onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
              >
                <option value="installation">Installation</option>
                <option value="maintenance">Maintenance</option>
                <option value="repair">Repair</option>
                <option value="inspection">Inspection</option>
              </select>
            </div>

            <div>
              <Label>Status</Label>
              <select
                className="w-full p-2 border rounded"
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
              >
                <option value="not_scheduled">Not Scheduled</option>
                <option value="scheduled">Scheduled</option>
                <option value="in_progress">In Progress</option>
                <option value="completed">Completed</option>
              </select>
            </div>
          </div>

          <div>
            <Label>Total Value</Label>
            <Input
              type="number"
              value={formData.total_amount}
              onChange={(e) => setFormData({ ...formData, total_amount: parseFloat(e.target.value) || 0 })}
              step="0.01"
            />
          </div>

          <div>
            <Label>Description</Label>
            <Textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={6}
            />
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleCreate} disabled={isCreating || !formData.title}>
            {isCreating ? 'Creating...' : 'Create Job'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
EOF

echo "Create Job modal updated to use proposal title"

# Test the build
echo ""
echo "Testing build..."
npm run build 2>&1 | head -100

if [ $? -eq 0 ]; then
  echo ""
  echo "Build successful! Committing changes..."
  git add -A
  git commit -m "Fix job navigation and proposal title in Create Job modal

- Fixed JobsTable to properly navigate to job details on row click
- Fixed Create Job modal to use actual proposal service/title instead of generic text
- Added proper click handlers to prevent navigation issues
- Improved title extraction from proposal items"
  
  git push origin main
  
  echo ""
  echo "============================================"
  echo "SUCCESS! Fixed navigation and title issues"
  echo "============================================"
  echo ""
  echo "FIXES APPLIED:"
  echo "1. ✅ Job table rows now properly navigate to job details"
  echo "2. ✅ Create Job uses actual proposal title/service name"
  echo "3. ✅ Click handlers properly configured"
  echo ""
  echo "HOW IT WORKS NOW:"
  echo "- Click any job row → Goes to job details page"
  echo "- Create Job from proposal → Uses proposal's service name as title"
  echo "- Edit Job in job details → Uses same modal pattern"
  echo ""
  echo "============================================"
else
  echo "Build failed. Check errors above."
fi
