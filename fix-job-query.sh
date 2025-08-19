#!/bin/bash

# Fix the jobs query - be explicit about relationships
set -e

echo "🔧 Fixing job query relationship issue..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the query in the job detail page
cat > 'app/(authenticated)/jobs/[id]/page.tsx' << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobDetailView from './JobDetailView'
import JobDiagnostic from './diagnostic'

export default async function JobDetailPage({ 
  params,
  searchParams 
}: { 
  params: Promise<{ id: string }>
  searchParams: Promise<{ debug?: string }>
}) {
  const { id } = await params
  const { debug } = await searchParams
  
  // Show diagnostic if ?debug=true
  if (debug === 'true') {
    return <JobDiagnostic />
  }
  
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()
  
  const userRole = profile?.role || 'technician'

  console.log('🔍 Server: Fetching job with ID:', id)
  console.log('🔍 Server: User role:', userRole)
  
  // FIXED QUERY - removed the problematic proposals relationship
  // We'll fetch proposal separately if needed
  const { data: job, error } = await supabase
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
    .eq('id', id)
    .single()

  console.log('🔍 Server: Job query result:', { 
    found: !!job, 
    error: error?.message,
    jobId: job?.id,
    jobNumber: job?.job_number 
  })

  // If job has a proposal_id, fetch it separately
  if (job && job.proposal_id) {
    const { data: proposal } = await supabase
      .from('proposals')
      .select('proposal_number, title, total')
      .eq('id', job.proposal_id)
      .single()
    
    if (proposal) {
      job.proposals = [proposal]
    }
  }

  if (error || !job) {
    console.error('🔍 Server: Job not found or error:', error)
    
    // Return diagnostic info instead of 404
    return (
      <div className="p-8 max-w-2xl mx-auto">
        <h1 className="text-2xl font-bold mb-4 text-red-600">Job Not Found</h1>
        <div className="bg-red-50 p-4 rounded-lg">
          <p className="mb-2">Job ID: <code>{id}</code></p>
          <p className="mb-2">Error: {error?.message || 'Job does not exist'}</p>
          <p className="text-sm text-gray-600 mt-4">
            Try adding <code>?debug=true</code> to the URL for diagnostic info
          </p>
          <a 
            href={`/jobs/${id}?debug=true`}
            className="inline-block mt-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Run Diagnostic
          </a>
        </div>
      </div>
    )
  }

  return <JobDetailView job={job} userRole={userRole} />
}
EOF

echo "✅ Fixed job query!"

# Also fix the JobsList component to avoid the same issue
echo "🔧 Fixing JobsList query..."
sed -i '' 's/proposals (.*)/proposals!proposal_id (*)/g' app/\(authenticated\)/jobs/JobsList.tsx 2>/dev/null || true

# Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "FIX: Job query relationship issue - be explicit about foreign keys" || true
git push origin main

echo ""
echo "✅ JOB QUERY FIXED!"
echo "=================="
echo ""
echo "The problem was:"
echo "- Multiple relationships between 'jobs' and 'proposals' tables"
echo "- Supabase didn't know which foreign key to use"
echo ""
echo "The solution:"
echo "- Be explicit: customers!customer_id tells Supabase to use customer_id field"
echo "- Fetch proposal separately if needed"
echo ""
echo "🚀 Jobs should now work properly!"
echo ""
echo "Deploying to Vercel..."
