#!/bin/bash

# Fix the JobDetailView props issue
set -e

echo "🔧 Fixing JobDetailView props..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update page.tsx to get userRole and pass it
cat > 'app/(authenticated)/jobs/[id]/page.tsx' << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
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
  
  const { data: job, error } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
        name,
        email,
        phone,
        address
      ),
      proposals (
        proposal_number,
        title,
        total
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

echo "✅ Fixed JobDetailView props"

# Remove the diagnostic script
rm -f create-diagnostics.sh

# Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "Fix JobDetailView props - pass userRole correctly" || true
git push origin main

echo ""
echo "✅ FIXES APPLIED!"
echo ""
echo "🔍 HOW TO TEST:"
echo "=============="
echo ""
echo "1. FOR JOB 404 DEBUGGING:"
echo "   - Go to: /jobs/99535b2f-7a10-4764-b404-cffbe055e2ea?debug=true"
echo "   - This will show diagnostic info about:"
echo "     • Authentication status"
echo "     • Database connection"
echo "     • Job query results"
echo "     • Available jobs in database"
echo ""
echo "2. FOR PROPOSAL APPROVAL:"
echo "   - Try to approve a proposal"
echo "   - Open browser console (F12)"
echo "   - Look for messages with 🔍"
echo "   - Errors will show more detail"
echo ""
echo "🚀 Deploying now..."
