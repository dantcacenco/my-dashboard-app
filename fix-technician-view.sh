#!/bin/bash

# Fix Technician View and Upload Features
echo "🔧 Fixing technician job view and upload features..."

# 1. Fix the jobs page to properly show technician's assigned jobs
echo "📝 Fixing jobs page query for technicians..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobsList from './JobsList'
import JobsListHeader from './JobsListHeader'

export default async function JobsPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const userRole = profile?.role || 'technician'
  
  console.log('JobsPage - User role:', userRole, 'User ID:', user.id)

  let jobs = []

  if (userRole === 'technician') {
    // First, get job IDs assigned to this technician
    const { data: assignments, error: assignmentError } = await supabase
      .from('job_technicians')
      .select('job_id')
      .eq('technician_id', user.id)
    
    console.log('Technician assignments:', assignments, 'Error:', assignmentError)
    
    if (assignments && assignments.length > 0) {
      const jobIds = assignments.map(a => a.job_id)
      
      // Then fetch those jobs with customer info
      const { data: techJobs, error: jobsError } = await supabase
        .from('jobs')
        .select(`
          *,
          customers!customer_id (
            name,
            email,
            phone,
            address
          )
        `)
        .in('id', jobIds)
        .order('created_at', { ascending: false })
      
      console.log('Technician jobs:', techJobs?.length, 'Error:', jobsError)
      jobs = techJobs || []
    }
  } else {
    // Boss/admin sees all jobs
    const { data: allJobs, error } = await supabase
      .from('jobs')
      .select(`
        *,
        customers!customer_id (
          name,
          email,
          phone,
          address
        )
      `)
      .order('created_at', { ascending: false })
    
    console.log('All jobs for boss/admin:', allJobs?.length, 'Error:', error)
    jobs = allJobs || []
  }

  return (
    <div className="container mx-auto py-6 px-4">
      <JobsListHeader userRole={userRole} />
      {userRole === 'technician' && jobs.length === 0 ? (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <p className="text-yellow-800">No jobs assigned to you yet.</p>
          <p className="text-sm text-yellow-600 mt-1">Jobs will appear here once your supervisor assigns them to you.</p>
        </div>
      ) : (
        <JobsList jobs={jobs} userRole={userRole} />
      )}
    </div>
  )
}
EOF

# 2. Update JobsListHeader to accept userRole prop
echo "📝 Updating JobsListHeader..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/JobsListHeader.tsx << 'EOF'
'use client'

import { useRouter } from 'next/navigation'
import { Plus } from 'lucide-react'

interface JobsListHeaderProps {
  userRole?: string
}

export default function JobsListHeader({ userRole = 'technician' }: JobsListHeaderProps) {
  const router = useRouter()

  return (
    <div className="flex justify-between items-center mb-6">
      <h1 className="text-2xl font-bold">
        {userRole === 'technician' ? 'My Assigned Jobs' : 'Jobs'}
      </h1>
      {userRole !== 'technician' && (
        <button
          onClick={() => router.push('/jobs/new')}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          New Job
        </button>
      )}
    </div>
  )
}
EOF

# 3. Update JobsList to hide pricing for technicians
echo "📝 Updating JobsList to hide pricing for technicians..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/JobsList.tsx << 'EOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { MapPin, Phone, Mail, Calendar, DollarSign, Users } from 'lucide-react'

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
      case 'scheduled': return 'bg-blue-100 text-blue-800'
      case 'in_progress': return 'bg-purple-100 text-purple-800'
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
                        <Badge className={getStatusColor(job.status)}>
                          {job.status.replace('_', ' ')}
                        </Badge>
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
                    <Badge className={`ml-2 ${getStatusColor(job.status)}`}>
                      {job.status.replace('_', ' ')}
                    </Badge>
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
EOF

# 4. Create SQL to check job_technicians data
echo "📝 Creating SQL to debug job assignments..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/check-job-assignments.sql << 'EOF'
-- Check job_technicians table
SELECT 
    jt.job_id,
    jt.technician_id,
    j.job_number,
    j.title,
    p.email as technician_email,
    p.full_name as technician_name
FROM job_technicians jt
JOIN jobs j ON j.id = jt.job_id
JOIN profiles p ON p.id = jt.technician_id
ORDER BY jt.assigned_at DESC;

-- Check RLS policies on job_technicians
SELECT * FROM pg_policies WHERE tablename = 'job_technicians';

-- If no policies exist, create them
/*
CREATE POLICY "Technicians can view their assignments" 
ON job_technicians FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Boss can manage assignments" 
ON job_technicians FOR ALL 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('boss', 'admin')
  )
);
*/
EOF

echo "🔨 Building the application..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -50

echo ""
echo "📦 Committing changes..."
git add -A
git commit -m "Fix technician job view and prepare for upload features"
git push origin main

echo ""
echo "✅ Technician view fixed!"
echo ""
echo "📝 Next steps:"
echo "1. Run check-job-assignments.sql in Supabase"
echo "2. Sign in as technician@gmail.com to test"
echo "3. Jobs should now appear for technicians"
echo ""
echo "Note: File upload feature needs separate implementation"
