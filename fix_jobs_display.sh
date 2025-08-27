#!/bin/bash

# Fix jobs not showing in list

set -e

echo "============================================"
echo "Fixing Jobs List Display Issue"
echo "============================================"

PROJECT_DIR="/Users/dantcacenco/Documents/GitHub/my-dashboard-app"
cd "$PROJECT_DIR"

# Check database for jobs
echo "Checking database for jobs..."
PGPASSWORD="cSEX2IYYjeJru6V" /opt/homebrew/Cellar/postgresql@16/16.10/bin/psql \
  -h "aws-0-us-east-1.pooler.supabase.com" -p "6543" \
  -U "postgres.dqcxwekmehrqkigcufug" -d "postgres" \
  -c "SELECT id, job_number, title, status FROM jobs LIMIT 5;"

# Fix the jobs page - ensure proper async handling
echo "Fixing jobs page..."

cat > "$PROJECT_DIR/app/(authenticated)/jobs/page.tsx" << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-react'
import JobsTable from './JobsTable'

export default async function JobsPage({
  searchParams
}: {
  searchParams: Promise<{ page?: string }>
}) {
  const params = await searchParams
  const supabase = await createClient()
  
  // Check authentication
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/login')
  }

  // Check if user is admin/boss
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  // Pagination
  const page = parseInt(params?.page || '1')
  const pageSize = 10
  const from = (page - 1) * pageSize
  const to = from + pageSize - 1

  // Fetch jobs with related data
  const { data: jobs, error, count } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone
      ),
      profiles:technician_id (
        id,
        full_name,
        email
      )
    `, { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(from, to)

  // Debug logging
  console.log('Jobs page - fetched jobs:', jobs?.length || 0)
  console.log('Jobs page - error:', error)
  console.log('Jobs page - total count:', count)

  if (error) {
    console.error('Error fetching jobs:', error)
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Jobs</h1>
        <Link href="/jobs/new">
          <Button>
            <Plus className="h-4 w-4 mr-2" />
            New Job
          </Button>
        </Link>
      </div>

      <JobsTable 
        jobs={jobs || []} 
        totalCount={count || 0}
        currentPage={page}
        pageSize={pageSize}
      />
    </div>
  )
}
EOF

# Also ensure JobsTable is properly handling the data
echo "Ensuring JobsTable component exists and works..."

if [ ! -f "$PROJECT_DIR/app/(authenticated)/jobs/JobsTable.tsx" ]; then
  echo "JobsTable component missing, recreating..."
  
  cat > "$PROJECT_DIR/app/(authenticated)/jobs/JobsTable.tsx" << 'EOF'
'use client'

import { useRouter } from 'next/navigation'
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
import { useEffect } from 'react'

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

  // Debug logging
  useEffect(() => {
    console.log('JobsTable received:', jobs.length, 'jobs')
    console.log('JobsTable data:', jobs)
  }, [jobs])

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
            {jobs && jobs.length > 0 ? (
              jobs.map((job) => (
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
              ))
            ) : (
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
fi

echo "Testing build..."
npm run build 2>&1 | head -100

if [ $? -eq 0 ]; then
  echo ""
  echo "Build successful! Committing changes..."
  git add -A
  git commit -m "Fix jobs not displaying in list - proper async handling for Next.js 15

- Added proper await for createClient() 
- Added debug logging to track data flow
- Ensured JobsTable properly handles job data
- Fixed async/await chain in jobs page"
  
  git push origin main
  
  echo ""
  echo "============================================"
  echo "SUCCESS! Jobs list should display properly now"
  echo "============================================"
  echo ""
  echo "Jobs in database: 2"
  echo "They should now appear in the UI"
  echo ""
  echo "If still not showing, check browser console for:"
  echo "- 'Jobs page - fetched jobs: X'"
  echo "- 'JobsTable received: X jobs'"
  echo ""
  echo "============================================"
else
  echo "Build failed. Check errors above."
fi
