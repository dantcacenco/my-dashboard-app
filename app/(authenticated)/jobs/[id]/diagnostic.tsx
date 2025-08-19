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
