#!/bin/bash

# Fix Technician Portal, File Uploads, and Customer Proposals
echo "🔧 Starting comprehensive fixes..."

# 1. Create Technician Jobs View (rename from Tasks)
echo "📝 Creating technician jobs view..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/jobs/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianJobsList from './TechnicianJobsList'

export default async function TechnicianJobsPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role, full_name')
    .eq('id', user.id)
    .single()

  // Only technicians can access this
  if (profile?.role !== 'technician') {
    redirect('/')
  }

  // Get jobs assigned to this technician
  const { data: assignedJobs } = await supabase
    .from('job_technicians')
    .select(`
      job_id,
      jobs (
        id,
        job_number,
        title,
        description,
        job_type,
        status,
        scheduled_date,
        scheduled_time,
        service_address,
        notes,
        customer_name,
        customer_phone,
        customer_email,
        created_at,
        job_photos (
          id,
          photo_url,
          caption,
          created_at
        ),
        job_files (
          id,
          file_name,
          file_url,
          created_at
        )
      )
    `)
    .eq('technician_id', user.id)
    .order('assigned_at', { ascending: false })

  // Flatten the jobs data
  const jobs = assignedJobs?.map(item => item.jobs).filter(Boolean) || []

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">My Jobs</h1>
        <p className="text-gray-600">Welcome back, {profile?.full_name || 'Technician'}</p>
      </div>
      
      <TechnicianJobsList jobs={jobs} technicianId={user.id} />
    </div>
  )
}
EOF

# 2. Create Technician Jobs List Component
echo "📝 Creating technician jobs list component..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/jobs/TechnicianJobsList.tsx << 'EOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Calendar, MapPin, Phone, Mail, FileText, Camera, ChevronDown, ChevronUp } from 'lucide-react'

interface TechnicianJobsListProps {
  jobs: any[]
  technicianId: string
}

export default function TechnicianJobsList({ jobs, technicianId }: TechnicianJobsListProps) {
  const [expandedJob, setExpandedJob] = useState<string | null>(null)

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled': return 'bg-blue-100 text-blue-800'
      case 'in_progress': return 'bg-yellow-100 text-yellow-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const formatTime = (time: string) => {
    if (!time) return 'Not set'
    try {
      const [hours, minutes] = time.split(':')
      const hour = parseInt(hours)
      const ampm = hour >= 12 ? 'PM' : 'AM'
      const displayHour = hour % 12 || 12
      return `${displayHour}:${minutes} ${ampm}`
    } catch {
      return time
    }
  }

  if (jobs.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow p-8 text-center">
        <p className="text-gray-500">No jobs assigned to you yet.</p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {jobs.map((job) => (
        <div key={job.id} className="bg-white rounded-lg shadow overflow-hidden">
          {/* Job Header */}
          <div
            className="p-4 cursor-pointer hover:bg-gray-50"
            onClick={() => setExpandedJob(expandedJob === job.id ? null : job.id)}
          >
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <h3 className="font-semibold text-lg">{job.title}</h3>
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(job.status)}`}>
                    {job.status.replace('_', ' ').toUpperCase()}
                  </span>
                </div>
                
                <div className="text-sm text-gray-600 space-y-1">
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4" />
                    {job.scheduled_date ? formatDate(job.scheduled_date) : 'Not scheduled'}
                    {job.scheduled_time && ` at ${formatTime(job.scheduled_time)}`}
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <MapPin className="h-4 w-4" />
                    {job.service_address || 'No address specified'}
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <span className="text-gray-500">Job #{job.job_number}</span>
                  </div>
                </div>
              </div>
              
              <div>
                {expandedJob === job.id ? (
                  <ChevronUp className="h-5 w-5 text-gray-400" />
                ) : (
                  <ChevronDown className="h-5 w-5 text-gray-400" />
                )}
              </div>
            </div>
          </div>

          {/* Expanded Content */}
          {expandedJob === job.id && (
            <div className="border-t px-4 py-4 space-y-4">
              {/* Customer Info */}
              <div>
                <h4 className="font-medium mb-2">Customer Information</h4>
                <div className="bg-gray-50 rounded p-3 space-y-2 text-sm">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">Name:</span> {job.customer_name}
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone className="h-4 w-4" />
                    <a href={`tel:${job.customer_phone}`} className="text-blue-600 hover:underline">
                      {job.customer_phone}
                    </a>
                  </div>
                  <div className="flex items-center gap-2">
                    <Mail className="h-4 w-4" />
                    <a href={`mailto:${job.customer_email}`} className="text-blue-600 hover:underline">
                      {job.customer_email}
                    </a>
                  </div>
                </div>
              </div>

              {/* Job Details */}
              {job.description && (
                <div>
                  <h4 className="font-medium mb-2">Job Description</h4>
                  <div className="bg-gray-50 rounded p-3">
                    <p className="text-sm whitespace-pre-wrap">{job.description}</p>
                  </div>
                </div>
              )}

              {/* Notes */}
              {job.notes && (
                <div>
                  <h4 className="font-medium mb-2">Notes</h4>
                  <div className="bg-yellow-50 rounded p-3">
                    <p className="text-sm whitespace-pre-wrap">{job.notes}</p>
                  </div>
                </div>
              )}

              {/* Photos */}
              {job.job_photos && job.job_photos.length > 0 && (
                <div>
                  <h4 className="font-medium mb-2 flex items-center gap-2">
                    <Camera className="h-4 w-4" />
                    Photos ({job.job_photos.length})
                  </h4>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                    {job.job_photos.map((photo: any) => (
                      <a
                        key={photo.id}
                        href={photo.photo_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="block aspect-square bg-gray-100 rounded overflow-hidden hover:opacity-75"
                      >
                        <img
                          src={photo.photo_url}
                          alt={photo.caption || 'Job photo'}
                          className="w-full h-full object-cover"
                        />
                      </a>
                    ))}
                  </div>
                </div>
              )}

              {/* Files */}
              {job.job_files && job.job_files.length > 0 && (
                <div>
                  <h4 className="font-medium mb-2 flex items-center gap-2">
                    <FileText className="h-4 w-4" />
                    Files ({job.job_files.length})
                  </h4>
                  <div className="space-y-1">
                    {job.job_files.map((file: any) => (
                      <a
                        key={file.id}
                        href={file.file_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-2 p-2 bg-gray-50 rounded hover:bg-gray-100"
                      >
                        <FileText className="h-4 w-4 text-gray-500" />
                        <span className="text-sm text-blue-600 hover:underline">
                          {file.file_name}
                        </span>
                      </a>
                    ))}
                  </div>
                </div>
              )}

              {/* Actions */}
              <div className="flex gap-2 pt-2">
                <Link
                  href={`/technician/jobs/${job.id}`}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  View Full Details
                </Link>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  )
}
EOF

# 3. Update Navigation for Technicians
echo "📝 Updating navigation to show My Jobs for technicians..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/components/navigation/TechnicianNav.tsx << 'EOF'
'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Briefcase, Clock, User, LogOut } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export default function TechnicianNav() {
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()

  const handleSignOut = async () => {
    await supabase.auth.signOut()
    router.push('/auth/login')
  }

  const navItems = [
    { href: '/technician/jobs', label: 'My Jobs', icon: Briefcase },
    { href: '/technician/time', label: 'Time Tracking', icon: Clock },
    { href: '/technician/profile', label: 'Profile', icon: User },
  ]

  return (
    <nav className="bg-white shadow">
      <div className="container mx-auto px-4">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center gap-8">
            <h1 className="text-xl font-bold">Service Pro</h1>
            <div className="flex gap-6">
              {navItems.map((item) => {
                const Icon = item.icon
                const isActive = pathname.startsWith(item.href)
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`flex items-center gap-2 px-3 py-2 rounded transition-colors ${
                      isActive
                        ? 'bg-blue-50 text-blue-600'
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                  >
                    <Icon className="h-4 w-4" />
                    {item.label}
                  </Link>
                )
              })}
            </div>
          </div>
          
          <button
            onClick={handleSignOut}
            className="flex items-center gap-2 text-gray-600 hover:text-gray-900"
          >
            <LogOut className="h-4 w-4" />
            Sign Out
          </button>
        </div>
      </div>
    </nav>
  )
}
EOF

# 4. Fix Customer Proposal View with Add-ons
echo "📝 Fixing customer proposal view with add-on checkboxes..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/proposal/view/\[token\]/CustomerProposalView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import MobileDebug from '@/components/MobileDebug'

interface CustomerProposalViewProps {
  proposal: any
  token: string
}

export default function CustomerProposalView({ proposal: initialProposal, token }: CustomerProposalViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [proposal, setProposal] = useState(initialProposal)
  const [isApproving, setIsApproving] = useState(false)
  const [isRejecting, setIsRejecting] = useState(false)
  const [showRejectDialog, setShowRejectDialog] = useState(false)
  const [rejectionReason, setRejectionReason] = useState('')
  const [selectedAddons, setSelectedAddons] = useState<Set<string>>(new Set())
  const [proposalTotal, setProposalTotal] = useState(proposal.total)

  // Initialize selected addons from proposal items
  useEffect(() => {
    const initialAddons = new Set<string>()
    proposal.proposal_items?.forEach((item: any) => {
      // Only pre-select addons that are already selected
      if (item.is_addon && item.is_selected) {
        initialAddons.add(item.id)
      }
    })
    setSelectedAddons(initialAddons)
    calculateTotal(initialAddons)
  }, [])

  const calculateTotal = (addons: Set<string>) => {
    let subtotal = 0
    
    // Add base items (non-addons) - they're always included
    proposal.proposal_items?.forEach((item: any) => {
      if (!item.is_addon) {
        subtotal += item.total_price || 0
      } else if (addons.has(item.id)) {
        // Add selected addons
        subtotal += item.total_price || 0
      }
    })

    const taxAmount = subtotal * (proposal.tax_rate || 0)
    const total = subtotal + taxAmount
    
    setProposalTotal(total)
    return total
  }

  const toggleAddon = async (itemId: string) => {
    const newAddons = new Set(selectedAddons)
    if (newAddons.has(itemId)) {
      newAddons.delete(itemId)
    } else {
      newAddons.add(itemId)
    }
    setSelectedAddons(newAddons)
    
    // Update the proposal item selection in database
    const { error } = await supabase
      .from('proposal_items')
      .update({ is_selected: newAddons.has(itemId) })
      .eq('id', itemId)
    
    if (error) {
      console.error('Error updating addon:', error)
      toast.error('Failed to update selection')
      return
    }
    
    // Recalculate total
    const newTotal = calculateTotal(newAddons)
    
    // Update proposal total in database
    const { error: totalError } = await supabase
      .from('proposals')
      .update({ 
        total: newTotal,
        subtotal: newTotal / (1 + (proposal.tax_rate || 0)),
        tax_amount: newTotal - (newTotal / (1 + (proposal.tax_rate || 0)))
      })
      .eq('id', proposal.id)
    
    if (totalError) {
      console.error('Error updating total:', totalError)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const handleApprove = async () => {
    setIsApproving(true)
    try {
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: proposal.id,
          action: 'approve'
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || data.mobileMessage || 'Failed to approve proposal')
      }

      toast.success('Proposal approved successfully!')
      
      // Redirect to payment page
      if (data.redirectUrl) {
        router.push(data.redirectUrl)
      } else {
        router.push(`/proposal/view/${token}/payment`)
      }
    } catch (error: any) {
      console.error('Approval error:', error)
      toast.error(error.message || 'Failed to approve proposal')
      setIsApproving(false)
    }
  }

  const handleReject = async () => {
    setIsRejecting(true)
    try {
      const response = await fetch('/api/proposal-approval', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          proposalId: proposal.id,
          action: 'reject',
          rejectionReason
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || data.mobileMessage || 'Failed to reject proposal')
      }

      toast.success('Proposal rejected')
      setShowRejectDialog(false)
      
      // Refresh the proposal
      window.location.reload()
    } catch (error: any) {
      console.error('Rejection error:', error)
      toast.error(error.message || 'Failed to reject proposal')
    } finally {
      setIsRejecting(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          {/* Header */}
          <div className="bg-blue-600 text-white p-6">
            <h1 className="text-2xl font-bold">{proposal.title}</h1>
            <p className="mt-2">Proposal #{proposal.proposal_number}</p>
            <p className="text-sm mt-1 opacity-90">
              Valid until: {proposal.valid_until ? new Date(proposal.valid_until).toLocaleDateString() : 'No expiration'}
            </p>
          </div>

          {/* Customer Info */}
          <div className="p-6 border-b">
            <h2 className="text-lg font-semibold mb-3">Customer Information</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600">Name</p>
                <p className="font-medium">{proposal.customers?.name}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Email</p>
                <p className="font-medium">{proposal.customers?.email}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Phone</p>
                <p className="font-medium">{proposal.customers?.phone}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">Address</p>
                <p className="font-medium">{proposal.customers?.address}</p>
              </div>
            </div>
          </div>

          {/* Proposal Items */}
          <div className="p-6 border-b">
            <h2 className="text-lg font-semibold mb-3">Services & Options</h2>
            <div className="space-y-3">
              {/* Base Services */}
              <div className="mb-4">
                <h3 className="text-sm font-medium text-gray-700 mb-2">Included Services</h3>
                {proposal.proposal_items?.filter((item: any) => !item.is_addon).map((item: any) => (
                  <div key={item.id} className="p-3 rounded-lg border bg-gray-50 mb-2">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="font-medium">{item.name}</div>
                        {item.description && (
                          <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                        )}
                        <div className="text-sm text-gray-500 mt-1">
                          Qty: {item.quantity} × {formatCurrency(item.unit_price)}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="font-semibold">{formatCurrency(item.total_price)}</div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Add-ons */}
              {proposal.proposal_items?.filter((item: any) => item.is_addon).length > 0 && (
                <div>
                  <h3 className="text-sm font-medium text-gray-700 mb-2">
                    Optional Add-ons 
                    <span className="text-xs text-gray-500 ml-2">(Check to include)</span>
                  </h3>
                  {proposal.proposal_items?.filter((item: any) => item.is_addon).map((item: any) => (
                    <div 
                      key={item.id} 
                      className={`p-3 rounded-lg border mb-2 transition-colors ${
                        selectedAddons.has(item.id) 
                          ? 'bg-orange-50 border-orange-300' 
                          : 'bg-white border-gray-200'
                      }`}
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex items-start gap-3">
                          <input
                            type="checkbox"
                            checked={selectedAddons.has(item.id)}
                            onChange={() => toggleAddon(item.id)}
                            className="mt-1 h-5 w-5 text-orange-600 rounded cursor-pointer"
                            disabled={proposal.status !== 'sent'}
                          />
                          <div className="flex-1">
                            <div className="font-medium">
                              {item.name}
                              <span className="ml-2 text-xs bg-orange-200 text-orange-800 px-2 py-1 rounded">
                                ADD-ON
                              </span>
                            </div>
                            {item.description && (
                              <p className="text-sm text-gray-600 mt-1">{item.description}</p>
                            )}
                            <div className="text-sm text-gray-500 mt-1">
                              Qty: {selectedAddons.has(item.id) ? item.quantity : 0} × {formatCurrency(item.unit_price)}
                            </div>
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="font-semibold">
                            {selectedAddons.has(item.id) 
                              ? formatCurrency(item.total_price)
                              : formatCurrency(0)
                            }
                          </div>
                          {!selectedAddons.has(item.id) && (
                            <div className="text-xs text-gray-500">
                              +{formatCurrency(item.total_price)}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Totals */}
          <div className="p-6 bg-gray-50">
            <div className="space-y-2">
              <div className="flex justify-between text-lg">
                <span>Subtotal</span>
                <span>{formatCurrency(proposalTotal / (1 + (proposal.tax_rate || 0)))}</span>
              </div>
              <div className="flex justify-between text-lg">
                <span>Tax ({((proposal.tax_rate || 0) * 100).toFixed(2)}%)</span>
                <span>{formatCurrency(proposalTotal - (proposalTotal / (1 + (proposal.tax_rate || 0))))}</span>
              </div>
              <div className="flex justify-between text-xl font-bold pt-2 border-t">
                <span>Total</span>
                <span className="text-blue-600">{formatCurrency(proposalTotal)}</span>
              </div>
            </div>
          </div>

          {/* Actions */}
          {proposal.status === 'sent' && (
            <div className="p-6 bg-white border-t">
              <div className="flex flex-col sm:flex-row gap-3">
                <button
                  onClick={handleApprove}
                  disabled={isApproving}
                  className="flex-1 bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {isApproving ? (
                    <>Processing...</>
                  ) : (
                    <>
                      <CheckCircleIcon className="h-5 w-5" />
                      Approve Proposal
                    </>
                  )}
                </button>
                <button
                  onClick={() => setShowRejectDialog(true)}
                  className="flex-1 bg-red-600 text-white px-6 py-3 rounded-lg hover:bg-red-700 flex items-center justify-center gap-2"
                >
                  <XCircleIcon className="h-5 w-5" />
                  Reject Proposal
                </button>
              </div>
            </div>
          )}

          {/* Status Display */}
          {proposal.status !== 'sent' && (
            <div className="p-6 bg-white border-t">
              <div className={`text-center py-3 px-6 rounded-lg ${
                proposal.status === 'approved' ? 'bg-green-100 text-green-800' :
                proposal.status === 'rejected' ? 'bg-red-100 text-red-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                Proposal Status: {proposal.status.toUpperCase()}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Reject Dialog */}
      {showRejectDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full">
            <h3 className="text-lg font-semibold mb-3">Reject Proposal</h3>
            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="Please provide a reason for rejection (optional)"
              className="w-full p-3 border rounded-lg mb-4"
              rows={4}
            />
            <div className="flex gap-3">
              <button
                onClick={() => setShowRejectDialog(false)}
                className="flex-1 px-4 py-2 border rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={isRejecting}
                className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                {isRejecting ? 'Rejecting...' : 'Confirm Reject'}
              </button>
            </div>
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
git commit -m "Add technician jobs portal and fix customer proposal add-ons"
git push origin main

echo ""
echo "✅ All fixes applied!"
echo ""
echo "🎯 What was created/fixed:"
echo "1. Technician portal at /technician/jobs (renamed from tasks)"
echo "2. Jobs show all info except prices"
echo "3. Customer proposal view with proper add-on checkboxes"
echo "4. Add-ons highlighted in orange with checkboxes"
echo "5. Dynamic total calculation when add-ons are selected"
echo ""
echo "📝 Still need to fix:"
echo "- File/photo upload in job details"
echo "- Will address in next iteration"
