#!/bin/bash

# Fix All Remaining Issues
echo "🔧 Starting comprehensive fix for all remaining issues..."

# 1. Fix NewJobForm with better debugging and auto-fill
echo "📝 Fixing NewJobForm with debug logging..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/new/NewJobForm.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { ArrowLeft, Loader2, Plus } from 'lucide-react'
import Link from 'next/link'

interface NewJobFormProps {
  customers: any[]
  proposals: any[]
  technicians: any[]
  userId: string
}

export default function NewJobForm({ customers, proposals, technicians, userId }: NewJobFormProps) {
  const router = useRouter()
  const supabase = createClient()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [selectedTechnicians, setSelectedTechnicians] = useState<string[]>([])
  
  const [formData, setFormData] = useState({
    customer_id: '',
    proposal_id: '',
    title: '',
    description: '',
    job_type: 'repair',
    status: 'not_scheduled',
    service_address: '',
    scheduled_date: '',
    scheduled_time: '',
    total_value: '',
    notes: ''
  })

  // Debug logging on mount
  useEffect(() => {
    console.log('NewJobForm mounted with:', {
      customersCount: customers.length,
      proposalsCount: proposals.length,
      techniciansCount: technicians.length,
      technicians: technicians,
      userId: userId
    })
  }, [])

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const handleCustomerChange = (customerId: string) => {
    console.log('Customer changed:', customerId)
    const customer = customers.find(c => c.id === customerId)
    if (customer) {
      setFormData(prev => ({
        ...prev,
        customer_id: customerId,
        service_address: customer.address || ''
      }))
      console.log('Customer data:', customer)
    }
  }

  const handleProposalChange = (proposalId: string) => {
    console.log('Proposal changed:', proposalId)
    
    if (!proposalId) {
      // Clear proposal-related fields
      setFormData(prev => ({
        ...prev,
        proposal_id: '',
        title: '',
        description: '',
        total_value: ''
      }))
      return
    }
    
    const proposal = proposals.find(p => p.id === proposalId)
    console.log('Selected proposal:', proposal)
    
    if (proposal) {
      // Build description from proposal items
      const selectedItems = proposal.proposal_items?.filter((item: any) => 
        item.is_selected !== false
      ) || []
      
      const description = selectedItems.map((item: any) => 
        `${item.quantity}x ${item.name}${item.description ? ': ' + item.description : ''}`
      ).join('\n')

      const newFormData = {
        ...formData,
        proposal_id: proposalId,
        customer_id: proposal.customer_id,
        title: proposal.title || '',  // This should work now
        description: description,
        total_value: proposal.total?.toString() || '0',  // This should work now
        service_address: proposal.customers?.address || ''
      }
      
      console.log('Setting form data from proposal:', newFormData)
      setFormData(newFormData)
      
      // Also update customer fields
      if (proposal.customer_id) {
        handleCustomerChange(proposal.customer_id)
      }
    }
  }

  const toggleTechnician = (techId: string) => {
    console.log('Toggling technician:', techId)
    setSelectedTechnicians(prev =>
      prev.includes(techId)
        ? prev.filter(id => id !== techId)
        : [...prev, techId]
    )
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    console.log('Submitting form with data:', formData)
    console.log('Selected technicians:', selectedTechnicians)
    
    if (!formData.customer_id) {
      toast.error('Please select a customer')
      return
    }
    
    if (!formData.title) {
      toast.error('Please enter a job title')
      return
    }
    
    setIsSubmitting(true)

    try {
      const response = await fetch('/api/jobs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          ...formData,
          total_value: parseFloat(formData.total_value) || 0,
          technicianIds: selectedTechnicians
        })
      })

      const data = await response.json()
      console.log('API response:', data)

      if (!response.ok) {
        throw new Error(data.error || 'Failed to create job')
      }

      toast.success(`Job ${data.job.job_number} created successfully!`)
      router.push(`/jobs/${data.job.id}`)
    } catch (error: any) {
      console.error('Error creating job:', error)
      toast.error(error.message || 'Failed to create job')
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/jobs">
          <button
            type="button"
            className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Jobs
          </button>
        </Link>
      </div>

      {/* Link to Proposal (Optional) */}
      <div className="bg-blue-50 p-4 rounded-lg">
        <h3 className="font-medium mb-3">Link to Proposal (Optional)</h3>
        <select
          value={formData.proposal_id}
          onChange={(e) => handleProposalChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
        >
          <option value="">No proposal linked</option>
          {proposals.map((proposal) => (
            <option key={proposal.id} value={proposal.id}>
              {proposal.proposal_number} - {proposal.title} | {proposal.customers?.address || 'No address'} | {formatCurrency(proposal.total || 0)}
            </option>
          ))}
        </select>
        <p className="text-sm text-gray-600 mt-2">
          Linking to a proposal will auto-fill job details
        </p>
      </div>

      {/* Customer Selection */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Customer *
        </label>
        <select
          required
          value={formData.customer_id}
          onChange={(e) => handleCustomerChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
        >
          <option value="">Select a customer</option>
          {customers.map((customer) => (
            <option key={customer.id} value={customer.id}>
              {customer.name} - {customer.email}
            </option>
          ))}
        </select>
      </div>

      {/* Job Details */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Job Title *
          </label>
          <input
            type="text"
            required
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
            placeholder="e.g., AC Installation, Furnace Repair"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Job Type *
          </label>
          <select
            value={formData.job_type}
            onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
          >
            <option value="installation">Installation</option>
            <option value="repair">Repair</option>
            <option value="maintenance">Maintenance</option>
            <option value="inspection">Inspection</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Status *
          </label>
          <select
            value={formData.status}
            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
          >
            <option value="not_scheduled">Not Scheduled</option>
            <option value="scheduled">Scheduled</option>
            <option value="in_progress">In Progress</option>
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Total Value ($)
          </label>
          <input
            type="number"
            step="0.01"
            value={formData.total_value}
            onChange={(e) => setFormData({ ...formData, total_value: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
            placeholder="0.00"
          />
        </div>
      </div>

      {/* Description */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Description
        </label>
        <textarea
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          rows={4}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
          placeholder="Describe the work to be done..."
        />
      </div>

      {/* Schedule */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Scheduled Date
          </label>
          <input
            type="date"
            value={formData.scheduled_date}
            onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Scheduled Time
          </label>
          <input
            type="time"
            value={formData.scheduled_time}
            onChange={(e) => setFormData({ ...formData, scheduled_time: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-md"
          />
        </div>
      </div>

      {/* Service Address */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Service Address
        </label>
        <input
          type="text"
          value={formData.service_address}
          onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
          placeholder="Full service address"
        />
      </div>

      {/* Technician Assignment - With Debug Info */}
      <div>
        <h3 className="font-medium mb-3">
          Assign Technicians 
          <span className="text-sm text-gray-500 ml-2">
            ({technicians?.length || 0} available)
          </span>
        </h3>
        <div className="space-y-2 max-h-48 overflow-y-auto border rounded-lg p-3">
          {technicians && technicians.length > 0 ? (
            technicians.map((tech) => {
              console.log('Rendering technician:', tech)
              return (
                <label
                  key={tech.id}
                  className="flex items-center gap-3 p-2 hover:bg-gray-50 rounded cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={selectedTechnicians.includes(tech.id)}
                    onChange={() => toggleTechnician(tech.id)}
                    className="h-4 w-4 text-blue-600"
                  />
                  <span>{tech.full_name || tech.email}</span>
                </label>
              )
            })
          ) : (
            <div>
              <p className="text-sm text-gray-500">No active technicians found</p>
              <p className="text-xs text-red-500 mt-1">
                Debug: technicians array length = {technicians?.length || 0}
              </p>
              <button
                type="button"
                onClick={() => console.log('Technicians data:', technicians)}
                className="text-xs text-blue-500 underline mt-1"
              >
                Log technicians to console
              </button>
            </div>
          )}
        </div>
        {technicians && technicians.length > 0 && (
          <p className="text-sm text-gray-600 mt-2">
            {selectedTechnicians.length} technician(s) selected
          </p>
        )}
      </div>

      {/* Notes */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Internal Notes
        </label>
        <textarea
          value={formData.notes}
          onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          rows={3}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
          placeholder="Any additional notes..."
        />
      </div>

      {/* Submit Buttons */}
      <div className="flex justify-end gap-3 pt-4">
        <Link href="/jobs">
          <button
            type="button"
            className="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md"
          >
            Cancel
          </button>
        </Link>
        <button
          type="submit"
          disabled={isSubmitting}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 flex items-center"
        >
          {isSubmitting ? (
            <>
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              Creating...
            </>
          ) : (
            <>
              <Plus className="h-4 w-4 mr-2" />
              Create Job
            </>
          )}
        </button>
      </div>
    </form>
  )
}
EOF

# 2. Fix the page.tsx to properly fetch all data
echo "📝 Fixing job/new page to fetch all data correctly..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/new/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import NewJobForm from './NewJobForm'

export default async function NewJobPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()
  
  // Only boss/admin can create jobs
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/jobs')
  }

  // Fetch ALL data with proper joins
  const [customersRes, proposalsRes, techniciansRes] = await Promise.all([
    supabase
      .from('customers')
      .select('id, name, email, phone, address')
      .order('name'),
    
    supabase
      .from('proposals')
      .select(`
        id, 
        proposal_number, 
        title, 
        status, 
        customer_id,
        total,
        customers (
          name,
          address
        ),
        proposal_items (
          name,
          description,
          quantity,
          is_addon,
          is_selected
        )
      `)
      .eq('status', 'approved')
      .order('created_at', { ascending: false }),
    
    supabase
      .from('profiles')
      .select('id, email, full_name, role, is_active')
      .eq('role', 'technician')
      .eq('is_active', true)
      .order('full_name')
  ])

  console.log('Server: Fetched data:', {
    customers: customersRes.data?.length,
    proposals: proposalsRes.data?.length,
    technicians: techniciansRes.data?.length,
    technicianDetails: techniciansRes.data
  })

  // Debug log if no technicians
  if (!techniciansRes.data || techniciansRes.data.length === 0) {
    console.error('No technicians found. Check profiles table for role=technician and is_active=true')
  }

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-2xl font-bold mb-6">Create New Job</h1>
        <NewJobForm 
          customers={customersRes.data || []}
          proposals={proposalsRes.data || []}
          technicians={techniciansRes.data || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
EOF

# 3. Add proposal edit functionality to reset status to draft
echo "📝 Creating proposal edit API to reset status..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/api/proposals/\[id\]/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const supabase = await createClient()
    const body = await request.json()

    // Check auth
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // If proposal is being edited, reset status to draft
    const updateData = {
      ...body,
      status: 'draft',
      sent_at: null,
      first_viewed_at: null,
      approved_at: null,
      rejected_at: null,
      updated_at: new Date().toISOString()
    }

    const { data, error } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Error updating proposal:', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in PATCH /api/proposals/[id]:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
EOF

# 4. Fix mobile debug component to be visible on mobile
echo "📝 Creating mobile-friendly debug component..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/components/MobileDebug.tsx << 'EOF'
'use client'

import { useEffect, useState } from 'react'

interface MobileDebugProps {
  data: any
  title?: string
}

export default function MobileDebug({ data, title = 'Debug Info' }: MobileDebugProps) {
  const [showDebug, setShowDebug] = useState(false)
  const [isMinimized, setIsMinimized] = useState(false)

  useEffect(() => {
    // Check if debug mode is enabled in URL
    const params = new URLSearchParams(window.location.search)
    if (params.get('debug') === 'true') {
      setShowDebug(true)
      console.log('Debug mode enabled. Data:', data)
    }
  }, [data])

  if (!showDebug) return null

  return (
    <div 
      className={`fixed z-50 bg-black text-green-400 rounded-lg font-mono shadow-2xl transition-all ${
        isMinimized 
          ? 'bottom-4 right-4 w-auto p-2' 
          : 'bottom-0 left-0 right-0 max-h-[50vh] overflow-auto p-4'
      }`}
      style={{ fontSize: '10px' }}
    >
      <div className="flex justify-between items-center mb-2">
        <div className="font-bold">🐛 {title}</div>
        <button 
          onClick={() => setIsMinimized(!isMinimized)}
          className="px-2 py-1 bg-green-400 text-black rounded text-xs ml-4"
        >
          {isMinimized ? '📖' : '📕'}
        </button>
      </div>
      
      {!isMinimized && (
        <div className="space-y-2">
          <pre className="whitespace-pre-wrap break-all">
            {JSON.stringify(data, null, 2)}
          </pre>
          
          <div className="mt-4 space-y-1">
            <div>URL: {typeof window !== 'undefined' ? window.location.href : ''}</div>
            <div>User Agent: {typeof navigator !== 'undefined' ? navigator.userAgent : ''}</div>
            <div>Screen: {typeof window !== 'undefined' ? `${window.screen.width}x${window.screen.height}` : ''}</div>
          </div>
        </div>
      )}
    </div>
  )
}
EOF

echo "🔨 Building the application..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -50

echo ""
echo "📦 Committing changes..."
git add -A
git commit -m "Fix job form auto-fill, technicians, and add mobile debug"
git push origin main

echo ""
echo "✅ Fixes applied!"
echo ""
echo "🎯 What was fixed:"
echo "1. Added extensive console logging to debug technician and proposal issues"
echo "2. Fixed proposal data fetching to include all needed fields"
echo "3. Added proposal edit API that resets status to draft"
echo "4. Created mobile-friendly debug component"
echo ""
echo "📝 Please check browser console for:"
echo "- Technician data when page loads"
echo "- Proposal data when selecting a proposal"
echo "- Any error messages"
echo ""
echo "🔍 Debug URLs:"
echo "Add ?debug=true to any page URL to see debug info"
