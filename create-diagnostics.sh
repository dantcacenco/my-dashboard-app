#!/bin/bash

# Create diagnostic tools to troubleshoot issues
set -e

echo "🔍 Creating diagnostic tools for troubleshooting..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Create a diagnostic page for jobs
echo "📊 Creating job diagnostic page..."
cat > 'app/(authenticated)/jobs/[id]/diagnostic.tsx' << 'EOF'
'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useParams } from 'next/navigation'

export default function JobDiagnostic() {
  const params = useParams()
  const [diagnostic, setDiagnostic] = useState<any>({})
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    runDiagnostic()
  }, [])

  const runDiagnostic = async () => {
    const diag: any = {
      timestamp: new Date().toISOString(),
      jobId: params.id,
      url: window.location.href,
      pathname: window.location.pathname,
    }

    // Check auth
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    diag.auth = {
      isAuthenticated: !!user,
      userId: user?.id,
      email: user?.email,
      authError: authError?.message
    }

    // Try to fetch job
    if (params.id) {
      const { data: job, error: jobError } = await supabase
        .from('jobs')
        .select('*')
        .eq('id', params.id)
        .single()
      
      diag.job = {
        found: !!job,
        data: job,
        error: jobError?.message,
        errorDetails: jobError
      }

      // Check if job exists at all
      const { count, error: countError } = await supabase
        .from('jobs')
        .select('*', { count: 'exact', head: true })
        .eq('id', params.id)
      
      diag.jobCount = {
        count,
        error: countError?.message
      }
    }

    // List all jobs
    const { data: allJobs, error: allJobsError } = await supabase
      .from('jobs')
      .select('id, job_number, title')
      .limit(10)
    
    diag.allJobs = {
      count: allJobs?.length,
      sample: allJobs,
      error: allJobsError?.message
    }

    // Check tables
    const { data: tables } = await supabase
      .from('jobs')
      .select('*')
      .limit(0)
    
    diag.tablesExist = {
      jobs: tables !== null
    }

    setDiagnostic(diag)
    setLoading(false)
    
    // Log to console for debugging
    console.log('🔍 JOB DIAGNOSTIC REPORT:', diag)
  }

  if (loading) return <div className="p-8">Running diagnostic...</div>

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Job Diagnostic Report</h1>
      
      <div className="bg-gray-100 p-4 rounded-lg mb-4">
        <h2 className="font-bold mb-2">URL Info</h2>
        <p>Job ID: <code className="bg-white px-2 py-1 rounded">{diagnostic.jobId}</code></p>
        <p>URL: <code className="bg-white px-2 py-1 rounded text-xs">{diagnostic.url}</code></p>
        <p>Path: <code className="bg-white px-2 py-1 rounded">{diagnostic.pathname}</code></p>
      </div>

      <div className="bg-gray-100 p-4 rounded-lg mb-4">
        <h2 className="font-bold mb-2">Authentication</h2>
        <p>Authenticated: <span className={diagnostic.auth?.isAuthenticated ? 'text-green-600' : 'text-red-600'}>
          {diagnostic.auth?.isAuthenticated ? '✅ Yes' : '❌ No'}
        </span></p>
        <p>User: {diagnostic.auth?.email || 'Not logged in'}</p>
        {diagnostic.auth?.authError && (
          <p className="text-red-600">Error: {diagnostic.auth.authError}</p>
        )}
      </div>

      <div className="bg-gray-100 p-4 rounded-lg mb-4">
        <h2 className="font-bold mb-2">Job Query Result</h2>
        <p>Job Found: <span className={diagnostic.job?.found ? 'text-green-600' : 'text-red-600'}>
          {diagnostic.job?.found ? '✅ Yes' : '❌ No'}
        </span></p>
        {diagnostic.job?.error && (
          <div className="mt-2 p-2 bg-red-100 rounded">
            <p className="text-red-600 font-bold">Error:</p>
            <pre className="text-xs">{diagnostic.job.error}</pre>
            {diagnostic.job?.errorDetails && (
              <details className="mt-2">
                <summary className="cursor-pointer text-sm">Error Details</summary>
                <pre className="text-xs mt-2">{JSON.stringify(diagnostic.job.errorDetails, null, 2)}</pre>
              </details>
            )}
          </div>
        )}
        {diagnostic.job?.data && (
          <details className="mt-2">
            <summary className="cursor-pointer">Job Data</summary>
            <pre className="text-xs mt-2 bg-white p-2 rounded">{JSON.stringify(diagnostic.job.data, null, 2)}</pre>
          </details>
        )}
      </div>

      <div className="bg-gray-100 p-4 rounded-lg mb-4">
        <h2 className="font-bold mb-2">Database Check</h2>
        <p>Jobs in database: {diagnostic.allJobs?.count || 0}</p>
        {diagnostic.allJobs?.sample && (
          <details className="mt-2">
            <summary className="cursor-pointer">Sample Jobs</summary>
            <pre className="text-xs mt-2 bg-white p-2 rounded">{JSON.stringify(diagnostic.allJobs.sample, null, 2)}</pre>
          </details>
        )}
      </div>

      <div className="bg-yellow-100 p-4 rounded-lg">
        <h2 className="font-bold mb-2">Console Output</h2>
        <p className="text-sm">Open browser console (F12) to see full diagnostic data</p>
        <p className="text-xs mt-2">Full report logged as: "🔍 JOB DIAGNOSTIC REPORT"</p>
      </div>
    </div>
  )
}
EOF

# 2. Update JobDetailView to include diagnostic
echo "📝 Adding diagnostic to JobDetailView..."
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

  console.log('🔍 Server: Fetching job with ID:', id)
  
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

  return <JobDetailView job={job} />
}
EOF

# 3. Create proposal diagnostic
echo "🔍 Creating proposal diagnostic..."
cat > 'app/proposal/view/[token]/diagnostic.tsx' << 'EOF'
'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'

export default function ProposalDiagnostic() {
  const params = useParams()
  const [diagnostic, setDiagnostic] = useState<any>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    runDiagnostic()
  }, [])

  const runDiagnostic = async () => {
    const diag: any = {
      timestamp: new Date().toISOString(),
      token: params.token,
      url: window.location.href,
    }

    // Test API endpoint
    try {
      const response = await fetch('/api/proposal-approval', {
        method: 'GET'
      })
      diag.apiEndpoint = {
        exists: response.ok || response.status === 405,
        status: response.status,
        statusText: response.statusText
      }
    } catch (error: any) {
      diag.apiEndpoint = {
        exists: false,
        error: error.message
      }
    }

    // Test with mock data
    try {
      const mockResponse = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: 'test',
          action: 'test',
          token: 'test'
        })
      })
      const mockData = await mockResponse.json()
      diag.apiTest = {
        status: mockResponse.status,
        response: mockData
      }
    } catch (error: any) {
      diag.apiTest = {
        error: error.message
      }
    }

    setDiagnostic(diag)
    setLoading(false)
    console.log('🔍 PROPOSAL DIAGNOSTIC:', diag)
  }

  if (loading) return <div className="p-8">Running diagnostic...</div>

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Proposal Diagnostic Report</h1>
      
      <div className="bg-gray-100 p-4 rounded-lg mb-4">
        <h2 className="font-bold mb-2">API Endpoint Check</h2>
        <p>Endpoint exists: <span className={diagnostic.apiEndpoint?.exists ? 'text-green-600' : 'text-red-600'}>
          {diagnostic.apiEndpoint?.exists ? '✅ Yes' : '❌ No'}
        </span></p>
        <p>Status: {diagnostic.apiEndpoint?.status} {diagnostic.apiEndpoint?.statusText}</p>
        {diagnostic.apiEndpoint?.error && (
          <p className="text-red-600">Error: {diagnostic.apiEndpoint.error}</p>
        )}
      </div>

      <div className="bg-gray-100 p-4 rounded-lg mb-4">
        <h2 className="font-bold mb-2">API Test Response</h2>
        <pre className="text-xs bg-white p-2 rounded">
          {JSON.stringify(diagnostic.apiTest, null, 2)}
        </pre>
      </div>

      <div className="bg-yellow-100 p-4 rounded-lg">
        <p className="text-sm">Check browser console for full diagnostic</p>
      </div>
    </div>
  )
}
EOF

# 4. Update CustomerProposalView to add diagnostic
echo "📝 Updating CustomerProposalView with better error handling..."
sed -i '' 's/alert(error.message || .Failed to approve proposal.*)/console.error("🔍 Approval Error:", error);\nalert(`Failed to approve proposal: ${error.message || "Unknown error"}\\nCheck console for details`)/' app/proposal/view/\[token\]/CustomerProposalView.tsx

echo "✅ Diagnostic tools created!"

# Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "Add diagnostic tools for troubleshooting job 404 and proposal approval issues" || true
git push origin main

echo ""
echo "🔍 DIAGNOSTIC TOOLS CREATED!"
echo "============================"
echo ""
echo "📊 How to use the diagnostic tools:"
echo ""
echo "1. FOR JOB 404 ISSUES:"
echo "   Go to any job that shows 404"
echo "   Add ?debug=true to the URL"
echo "   Example: /jobs/99535b2f-7a10-4764-b404-cffbe055e2ea?debug=true"
echo ""
echo "2. FOR PROPOSAL APPROVAL:"
echo "   Try to approve a proposal"
echo "   Check browser console (F12) for detailed error messages"
echo "   Look for messages starting with 🔍"
echo ""
echo "3. WHAT TO LOOK FOR:"
echo "   - Authentication status"
echo "   - Database query results"
echo "   - API endpoint responses"
echo "   - Exact error messages"
echo ""
echo "🚀 Deploying diagnostic tools now..."
echo "Once deployed, test and tell me what the diagnostic shows!"
