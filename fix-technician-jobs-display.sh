#!/bin/bash

# Fix technician page to show jobs properly
echo "Fixing technician jobs display..."

# Update technician page to directly query jobs
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianJobsList from './TechnicianJobsList'

export default async function TechnicianPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role, full_name')
    .eq('id', user.id)
    .single()

  // Check if user is a technician
  if (!profile || profile.role !== 'technician') {
    redirect('/')
  }

  // First get the job IDs assigned to this technician
  const { data: assignments } = await supabase
    .from('job_technicians')
    .select('job_id')
    .eq('technician_id', user.id)

  const jobIds = assignments?.map(a => a.job_id) || []

  // Now get the full job details for these job IDs
  let jobs = []
  if (jobIds.length > 0) {
    const { data: jobData } = await supabase
      .from('jobs')
      .select(`
        *,
        customers (
          id,
          name,
          email,
          phone,
          address
        )
      `)
      .in('id', jobIds)
      .order('created_at', { ascending: false })

    jobs = jobData || []
  }

  return <TechnicianJobsList jobs={jobs} technicianName={profile.full_name || user.email || 'Technician'} />
}
EOF

# Create TechnicianJobsList component (similar to admin JobsList)
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/TechnicianJobsList.tsx << 'EOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Plus, Grid, List } from 'lucide-react'

interface TechnicianJobsListProps {
  jobs: any[]
  technicianName: string
}

export default function TechnicianJobsList({ jobs, technicianName }: TechnicianJobsListProps) {
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list')

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'Not scheduled'
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'not_scheduled': return 'text-gray-500 bg-gray-100'
      case 'scheduled': return 'text-blue-600 bg-blue-100'
      case 'in_progress': return 'text-yellow-600 bg-yellow-100'
      case 'completed': return 'text-green-600 bg-green-100'
      case 'cancelled': return 'text-red-600 bg-red-100'
      default: return 'text-gray-500 bg-gray-100'
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">My Jobs</h1>
          <p className="text-muted-foreground">Welcome, {technicianName}</p>
        </div>
        <div className="flex gap-2">
          <Button
            variant={viewMode === 'list' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('list')}
          >
            <List className="h-4 w-4" />
            List View
          </Button>
          <Button
            variant={viewMode === 'grid' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('grid')}
          >
            <Grid className="h-4 w-4" />
            Grid View
          </Button>
        </div>
      </div>

      {/* Jobs Table/Grid */}
      {jobs.length === 0 ? (
        <div className="text-center py-12 bg-gray-50 rounded-lg">
          <p className="text-gray-500">No jobs assigned yet</p>
          <p className="text-sm text-gray-400 mt-2">Jobs will appear here once they are assigned to you</p>
        </div>
      ) : viewMode === 'list' ? (
        <div className="bg-white shadow-sm rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Job #
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Customer
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Title
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Address
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Scheduled
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {jobs.map((job) => (
                <tr
                  key={job.id}
                  className="hover:bg-gray-50 cursor-pointer"
                  onClick={() => window.location.href = `/technician/jobs/${job.id}`}
                >
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-blue-600">
                    {job.job_number}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">
                      {job.customers?.name || job.customer_name || 'N/A'}
                    </div>
                    <div className="text-sm text-gray-500">
                      {job.customers?.phone || ''}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-900">{job.title || 'No title'}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-900">{job.service_address || job.customers?.address || 'No address'}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(job.status)}`}>
                      {job.status.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {formatDate(job.scheduled_date)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {jobs.map((job) => (
            <Link key={job.id} href={`/technician/jobs/${job.id}`}>
              <div className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow p-6 cursor-pointer">
                <div className="flex justify-between items-start mb-3">
                  <h3 className="text-lg font-semibold text-blue-600">
                    {job.job_number}
                  </h3>
                  <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(job.status)}`}>
                    {job.status.replace('_', ' ')}
                  </span>
                </div>
                <p className="text-gray-900 font-medium mb-2">{job.title || 'No title'}</p>
                <p className="text-sm text-gray-600 mb-1">
                  {job.customers?.name || job.customer_name || 'No customer'}
                </p>
                <p className="text-sm text-gray-500 mb-3">
                  {job.service_address || job.customers?.address || 'No address'}
                </p>
                <p className="text-sm text-gray-500">
                  {formatDate(job.scheduled_date)}
                </p>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
EOF

# Build and deploy
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -20

git add -A
git commit -m "Fix technician jobs display - show full jobs list like admin view"
git push origin main

echo "✅ Fixed technician jobs display!"
echo "Now showing jobs in same format as admin jobs list"
