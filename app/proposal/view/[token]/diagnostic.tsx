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
