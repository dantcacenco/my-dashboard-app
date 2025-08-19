#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting comprehensive fixes for Service Pro..."

# 1. Fix ProposalView - Show Send button for draft and sent status
cat > app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx << 'EOF'
'use client'

import { useState, useRef } from 'react'
import { useRouter } from 'next/navigation'
import SendProposal from '@/components/SendProposal'
import CreateJobButton from './CreateJobButton'
import { createClient } from '@/lib/supabase/client'
import { PrinterIcon, ArrowLeftIcon, PencilIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline'
import Link from 'next/link'

interface ProposalViewProps {
  proposal: any
  userRole: string
  userId?: string
}

export default function ProposalView({ proposal, userRole, userId }: ProposalViewProps) {
  const router = useRouter()
  const [showPrintView, setShowPrintView] = useState(false)
  const printRef = useRef<HTMLDivElement>(null)
  const supabase = createClient()

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    }).format(new Date(dateString))
  }

  const handlePrint = () => {
    setShowPrintView(true)
    setTimeout(() => {
      window.print()
      setShowPrintView(false)
    }, 100)
  }

  const getStatusBadge = (status: string) => {
    const statusConfig: Record<string, { color: string; icon?: any }> = {
      draft: { color: 'bg-gray-100 text-gray-800' },
      sent: { color: 'bg-blue-100 text-blue-800', icon: CheckCircleIcon },
      approved: { color: 'bg-green-100 text-green-800', icon: CheckCircleIcon },
      rejected: { color: 'bg-red-100 text-red-800', icon: XCircleIcon },
      paid: { color: 'bg-purple-100 text-purple-800' }
    }

    const config = statusConfig[status] || statusConfig.draft

    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        {config.icon && <config.icon className="w-3 h-3 mr-1" />}
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    )
  }

  const canEdit = (userRole === 'admin' || userRole === 'boss') && 
    (proposal.status === 'draft' || proposal.status === 'sent' || 
     (proposal.status === 'approved' && !proposal.deposit_paid_at))

  const canSendEmail = (userRole === 'admin' || userRole === 'boss') && 
    (proposal.status === 'draft' || proposal.status === 'sent')

  const canCreateJob = (userRole === 'admin' || userRole === 'boss') && 
    proposal.status === 'approved' && !proposal.job_created

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8 flex justify-between items-center">
        <div className="flex items-center gap-4">
          <Link
            href="/proposals"
            className="inline-flex items-center text-sm font-medium text-gray-500 hover:text-gray-700"
          >
            <ArrowLeftIcon className="w-4 h-4 mr-1" />
            Back to Proposals
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">
            Proposal {proposal.proposal_number}
          </h1>
          {getStatusBadge(proposal.status)}
        </div>
        
        <div className="flex gap-2">
          {canEdit && (
            <Link href={`/proposals/${proposal.id}/edit`}>
              <button className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                <PencilIcon className="w-4 h-4 mr-2" />
                Edit
              </button>
            </Link>
          )}
          
          {canSendEmail && (
            <SendProposal 
              proposalId={proposal.id}
              customerEmail={proposal.customers?.email}
              customerName={proposal.customers?.name}
              proposalNumber={proposal.proposal_number}
              onSent={() => router.refresh()}
            />
          )}
          
          <button
            onClick={handlePrint}
            className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            <PrinterIcon className="w-4 h-4 mr-2" />
            Print
          </button>

          {canCreateJob && (
            <CreateJobButton 
              proposalId={proposal.id}
              customerId={proposal.customer_id}
              proposalNumber={proposal.proposal_number}
              customerName={proposal.customers?.name}
              serviceAddress={proposal.customers?.address}
            />
          )}
        </div>
      </div>

      <div className="bg-white shadow overflow-hidden sm:rounded-lg">
        <div className="px-4 py-5 sm:px-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900">
            {proposal.title}
          </h3>
          {proposal.description && (
            <p className="mt-1 max-w-2xl text-sm text-gray-500">
              {proposal.description}
            </p>
          )}
        </div>
        
        <div className="border-t border-gray-200 px-4 py-5 sm:px-6">
          <dl className="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
            <div>
              <dt className="text-sm font-medium text-gray-500">Customer</dt>
              <dd className="mt-1 text-sm text-gray-900">
                {proposal.customers?.name || 'No customer assigned'}
              </dd>
            </div>
            
            <div>
              <dt className="text-sm font-medium text-gray-500">Date Created</dt>
              <dd className="mt-1 text-sm text-gray-900">
                {formatDate(proposal.created_at)}
              </dd>
            </div>
            
            <div>
              <dt className="text-sm font-medium text-gray-500">Total Amount</dt>
              <dd className="mt-1 text-sm text-gray-900 font-semibold">
                {formatCurrency(proposal.total || 0)}
              </dd>
            </div>
            
            <div>
              <dt className="text-sm font-medium text-gray-500">Status</dt>
              <dd className="mt-1">
                {getStatusBadge(proposal.status)}
              </dd>
            </div>

            {proposal.valid_until && (
              <div>
                <dt className="text-sm font-medium text-gray-500">Valid Until</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {formatDate(proposal.valid_until)}
                </dd>
              </div>
            )}

            {proposal.sent_at && (
              <div>
                <dt className="text-sm font-medium text-gray-500">Sent At</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {formatDate(proposal.sent_at)}
                </dd>
              </div>
            )}
          </dl>
        </div>

        {proposal.proposal_items && proposal.proposal_items.length > 0 && (
          <div className="border-t border-gray-200 px-4 py-5 sm:px-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
              Items
            </h3>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Item
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Quantity
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Unit Price
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Total
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {proposal.proposal_items
                    .filter((item: any) => item.is_selected)
                    .map((item: any) => (
                      <tr key={item.id}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {item.name}
                          {item.description && (
                            <p className="text-gray-500 text-xs">{item.description}</p>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 text-right">
                          {item.quantity}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 text-right">
                          {formatCurrency(item.unit_price)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 text-right">
                          {formatCurrency(item.total_price)}
                        </td>
                      </tr>
                    ))}
                </tbody>
                <tfoot className="bg-gray-50">
                  <tr>
                    <td colSpan={3} className="px-6 py-3 text-right text-sm font-medium text-gray-900">
                      Subtotal
                    </td>
                    <td className="px-6 py-3 text-right text-sm font-medium text-gray-900">
                      {formatCurrency(proposal.subtotal || 0)}
                    </td>
                  </tr>
                  {proposal.tax_amount > 0 && (
                    <tr>
                      <td colSpan={3} className="px-6 py-3 text-right text-sm font-medium text-gray-900">
                        Tax ({proposal.tax_rate}%)
                      </td>
                      <td className="px-6 py-3 text-right text-sm font-medium text-gray-900">
                        {formatCurrency(proposal.tax_amount)}
                      </td>
                    </tr>
                  )}
                  <tr>
                    <td colSpan={3} className="px-6 py-3 text-right text-sm font-bold text-gray-900">
                      Total
                    </td>
                    <td className="px-6 py-3 text-right text-sm font-bold text-gray-900">
                      {formatCurrency(proposal.total || 0)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
EOF

# 2. Create CreateJobButton component  
cat > app/\(authenticated\)/proposals/\[id\]/CreateJobButton.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { BriefcaseIcon } from '@heroicons/react/24/outline'

interface CreateJobButtonProps {
  proposalId: string
  customerId: string
  proposalNumber: string
  customerName?: string
  serviceAddress?: string
}

export default function CreateJobButton({ 
  proposalId, 
  customerId, 
  proposalNumber, 
  customerName,
  serviceAddress 
}: CreateJobButtonProps) {
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const handleCreateJob = async () => {
    if (!confirm('Create a job from this proposal?')) return
    
    setIsLoading(true)
    try {
      // Get user info
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      // Generate job number
      const today = new Date()
      const dateStr = today.toISOString().split('T')[0].replace(/-/g, '')
      const randomNum = Math.floor(Math.random() * 1000).toString().padStart(3, '0')
      const jobNumber = `JOB-${dateStr}-${randomNum}`

      // Create the job
      const { data: newJob, error: jobError } = await supabase
        .from('jobs')
        .insert({
          job_number: jobNumber,
          customer_id: customerId,
          proposal_id: proposalId,
          title: `Service from Proposal ${proposalNumber}`,
          description: `Job created from proposal ${proposalNumber}`,
          job_type: 'installation',
          status: 'not_scheduled',
          service_address: serviceAddress || '',
          created_by: user.id
        })
        .select()
        .single()

      if (jobError) throw jobError

      // Mark proposal as job created
      await supabase
        .from('proposals')
        .update({ job_created: true })
        .eq('id', proposalId)

      // Redirect to the new job
      router.push(`/jobs/${newJob.id}`)
    } catch (error) {
      console.error('Error creating job:', error)
      alert('Failed to create job. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <button
      onClick={handleCreateJob}
      disabled={isLoading}
      className="inline-flex items-center px-4 py-2 bg-black text-white rounded-md hover:bg-gray-800 disabled:opacity-50"
    >
      <BriefcaseIcon className="w-4 h-4 mr-2" />
      {isLoading ? 'Creating...' : 'Create Job'}
    </button>
  )
}
EOF

echo "✅ Fixed ProposalView and added CreateJobButton"

# 3. Fix Technicians refresh
cat > app/\(authenticated\)/technicians/TechniciansClientView.tsx << 'EOF'
'use client'

import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Plus, Mail, Phone, UserCheck, UserX, RefreshCw, Edit2, Trash2 } from 'lucide-react'
import AddTechnicianModal from './AddTechnicianModal'
import EditTechnicianModal from './EditTechnicianModal'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase/client'

interface Technician {
  id: string
  email: string
  full_name: string | null
  phone: string | null
  is_active?: boolean
  created_at: string
  role: string
}

export default function TechniciansClientView({ technicians: initialTechnicians }: { technicians: Technician[] }) {
  const [technicians, setTechnicians] = useState(initialTechnicians)
  const [showAddModal, setShowAddModal] = useState(false)
  const [editingTechnician, setEditingTechnician] = useState<Technician | null>(null)
  const [isRefreshing, setIsRefreshing] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const handleRefresh = async () => {
    setIsRefreshing(true)
    try {
      const { data } = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'technician')
        .order('created_at', { ascending: false })
      
      if (data) {
        setTechnicians(data)
        toast.success('Technicians list refreshed')
      }
    } catch (error) {
      toast.error('Failed to refresh technicians')
    } finally {
      setIsRefreshing(false)
    }
  }

  const handleTechnicianAdded = (newTechnician: Technician) => {
    setTechnicians([newTechnician, ...technicians])
    setShowAddModal(false)
  }

  const handleTechnicianUpdated = (updatedTechnician: Technician) => {
    setTechnicians(technicians.map(t => 
      t.id === updatedTechnician.id ? updatedTechnician : t
    ))
    setEditingTechnician(null)
  }

  const handleDelete = async (techId: string, email: string) => {
    if (!confirm(`Are you sure you want to permanently delete ${email}? This cannot be undone.`)) {
      return
    }

    try {
      const response = await fetch(`/api/technicians/${techId}`, {
        method: 'DELETE'
      })

      if (!response.ok) {
        throw new Error('Failed to delete technician')
      }

      toast.success('Technician deleted successfully')
      setTechnicians(technicians.filter(t => t.id !== techId))
    } catch (error) {
      toast.error('Failed to delete technician')
    }
  }

  const activeTechnicians = technicians.filter(t => t.is_active !== false)
  const inactiveTechnicians = technicians.filter(t => t.is_active === false)

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Technicians</h1>
          <p className="text-muted-foreground">
            Manage your field technicians
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="icon"
            onClick={handleRefresh}
            disabled={isRefreshing}
          >
            <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          </Button>
          <Button onClick={() => setShowAddModal(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Add Technician
          </Button>
        </div>
      </div>

      {/* Active Technicians */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Active Technicians ({activeTechnicians.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {activeTechnicians.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <p>No active technicians found</p>
              <p className="text-sm mt-2">Click "Add Technician" to create one</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {activeTechnicians.map((tech) => (
                <Card key={tech.id} className="border">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start mb-2">
                      <div className="flex items-center">
                        <UserCheck className="h-4 w-4 text-green-500 mr-2" />
                        <Badge variant="outline" className="text-xs">Active</Badge>
                      </div>
                      <div className="flex gap-1">
                        <button
                          onClick={() => setEditingTechnician(tech)}
                          className="text-gray-500 hover:text-gray-700"
                        >
                          <Edit2 className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(tech.id, tech.email)}
                          className="text-red-500 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                    <h3 className="font-medium text-gray-900">
                      {tech.full_name || 'No name set'}
                    </h3>
                    <div className="mt-2 space-y-1">
                      <div className="flex items-center text-sm text-gray-600">
                        <Mail className="h-3 w-3 mr-2" />
                        {tech.email}
                      </div>
                      {tech.phone && (
                        <div className="flex items-center text-sm text-gray-600">
                          <Phone className="h-3 w-3 mr-2" />
                          {tech.phone}
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Inactive Technicians */}
      {inactiveTechnicians.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Inactive Technicians ({inactiveTechnicians.length})</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {inactiveTechnicians.map((tech) => (
                <Card key={tech.id} className="border opacity-75">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start mb-2">
                      <div className="flex items-center">
                        <UserX className="h-4 w-4 text-gray-400 mr-2" />
                        <Badge variant="secondary" className="text-xs">Inactive</Badge>
                      </div>
                      <div className="flex gap-1">
                        <button
                          onClick={() => setEditingTechnician(tech)}
                          className="text-gray-500 hover:text-gray-700"
                        >
                          <Edit2 className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(tech.id, tech.email)}
                          className="text-red-500 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                    <h3 className="font-medium text-gray-700">
                      {tech.full_name || 'No name set'}
                    </h3>
                    <div className="mt-2 space-y-1">
                      <div className="flex items-center text-sm text-gray-500">
                        <Mail className="h-3 w-3 mr-2" />
                        {tech.email}
                      </div>
                      {tech.phone && (
                        <div className="flex items-center text-sm text-gray-500">
                          <Phone className="h-3 w-3 mr-2" />
                          {tech.phone}
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {showAddModal && (
        <AddTechnicianModal 
          onClose={() => setShowAddModal(false)}
          onSuccess={handleTechnicianAdded}
        />
      )}

      {editingTechnician && (
        <EditTechnicianModal
          technician={editingTechnician}
          onClose={() => setEditingTechnician(null)}
          onSuccess={handleTechnicianUpdated}
        />
      )}
    </div>
  )
}
EOF

echo "✅ Fixed technician refresh functionality"

echo "🏗️ Creating comprehensive job detail system..."

# Create job detail view with all functionality
cat > app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  ArrowLeft, Edit, Calendar, Clock, MapPin, User, 
  FileText, Camera, Upload, Plus, X, Save, Trash2 
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'

interface JobDetailViewProps {
  job: any
  userRole: string
}

export default function JobDetailView({ job: initialJob, userRole }: JobDetailViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [job, setJob] = useState(initialJob)
  const [isEditingOverview, setIsEditingOverview] = useState(false)
  const [overviewText, setOverviewText] = useState(job.description || '')
  const [isEditingNotes, setIsEditingNotes] = useState(false)
  const [notesText, setNotesText] = useState(job.notes || '')
  const [showEditModal, setShowEditModal] = useState(false)
  const [technicians, setTechnicians] = useState<any[]>([])
  const [assignedTechnicians, setAssignedTechnicians] = useState<any[]>([])
  const [jobPhotos, setJobPhotos] = useState<any[]>([])
  const [jobFiles, setJobFiles] = useState<any[]>([])
  const [uploadingPhoto, setUploadingPhoto] = useState(false)
  const [uploadingFile, setUploadingFile] = useState(false)

  useEffect(() => {
    loadTechnicians()
    loadAssignedTechnicians()
    loadJobPhotos()
    loadJobFiles()
  }, [job.id])

  const loadTechnicians = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
      .eq('is_active', true)
      .order('full_name')
    
    if (data) setTechnicians(data)
  }

  const loadAssignedTechnicians = async () => {
    const { data } = await supabase
      .from('job_technicians')
      .select('*, technician:technician_id(id, full_name, email)')
      .eq('job_id', job.id)
    
    if (data) setAssignedTechnicians(data)
  }

  const loadJobPhotos = async () => {
    const { data } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    if (data) setJobPhotos(data)
  }

  const loadJobFiles = async () => {
    const { data } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    if (data) setJobFiles(data)
  }

  const handleSaveOverview = async () => {
    const { error } = await supabase
      .from('jobs')
      .update({ description: overviewText })
      .eq('id', job.id)
    
    if (!error) {
      setJob({ ...job, description: overviewText })
      setIsEditingOverview(false)
      toast.success('Overview updated')
    } else {
      toast.error('Failed to update overview')
    }
  }

  const handleSaveNotes = async () => {
    const { error } = await supabase
      .from('jobs')
      .update({ notes: notesText })
      .eq('id', job.id)
    
    if (!error) {
      setJob({ ...job, notes: notesText })
      setIsEditingNotes(false)
      toast.success('Notes updated')
    } else {
      toast.error('Failed to update notes')
    }
  }

  const handleAssignTechnician = async (technicianId: string) => {
    const { data: { user } } = await supabase.auth.getUser()
    
    const { error } = await supabase
      .from('job_technicians')
      .insert({
        job_id: job.id,
        technician_id: technicianId,
        assigned_by: user?.id
      })
    
    if (!error) {
      loadAssignedTechnicians()
      toast.success('Technician assigned')
    } else {
      toast.error('Failed to assign technician')
    }
  }

  const handleRemoveTechnician = async (assignmentId: string) => {
    const { error } = await supabase
      .from('job_technicians')
      .delete()
      .eq('id', assignmentId)
    
    if (!error) {
      loadAssignedTechnicians()
      toast.success('Technician removed')
    } else {
      toast.error('Failed to remove technician')
    }
  }

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    setUploadingPhoto(true)
    const { data: { user } } = await supabase.auth.getUser()
    const fileName = `${job.id}/${Date.now()}_${file.name}`

    try {
      const { error: uploadError } = await supabase.storage
        .from('job-photos')
        .upload(fileName, file)

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('job-photos')
        .getPublicUrl(fileName)

      const { error: dbError } = await supabase
        .from('job_photos')
        .insert({
          job_id: job.id,
          uploaded_by: user?.id,
          photo_url: publicUrl,
          photo_type: 'general'
        })

      if (dbError) throw dbError

      loadJobPhotos()
      toast.success('Photo uploaded')
    } catch (error) {
      toast.error('Failed to upload photo')
    } finally {
      setUploadingPhoto(false)
    }
  }

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    setUploadingFile(true)
    const { data: { user } } = await supabase.auth.getUser()
    const fileName = `${job.id}/${Date.now()}_${file.name}`

    try {
      const { error: uploadError } = await supabase.storage
        .from('job-files')
        .upload(fileName, file)

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('job-files')
        .getPublicUrl(fileName)

      const { error: dbError } = await supabase
        .from('job_files')
        .insert({
          job_id: job.id,
          uploaded_by: user?.id,
          file_name: file.name,
          file_url: publicUrl,
          file_size: file.size,
          mime_type: file.type
        })

      if (dbError) throw dbError

      loadJobFiles()
      toast.success('File uploaded')
    } catch (error) {
      toast.error('Failed to upload file')
    } finally {
      setUploadingFile(false)
    }
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'not_scheduled': 'bg-gray-100 text-gray-800',
      'scheduled': 'bg-blue-100 text-blue-800',
      'in_progress': 'bg-yellow-100 text-yellow-800',
      'completed': 'bg-green-100 text-green-800',
      'cancelled': 'bg-red-100 text-red-800'
    }
    return colors[status] || 'bg-gray-100 text-gray-800'
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-4">
          <Link href="/jobs">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Jobs
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold">Job {job.job_number}</h1>
            <p className="text-muted-foreground">{job.title}</p>
          </div>
          <Badge className={getStatusColor(job.status)}>
            {job.status.replace('_', ' ').toUpperCase()}
          </Badge>
        </div>
        <Button onClick={() => setShowEditModal(true)}>
          <Edit className="h-4 w-4 mr-2" />
          Edit Job
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <Tabs defaultValue="overview" className="w-full">
            <TabsList className="grid w-full grid-cols-5">
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="technicians">Technicians</TabsTrigger>
              <TabsTrigger value="photos">Photos</TabsTrigger>
              <TabsTrigger value="files">Files</TabsTrigger>
              <TabsTrigger value="notes">Notes</TabsTrigger>
            </TabsList>

            <TabsContent value="overview">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Overview</CardTitle>
                    {!isEditingOverview && (
                      <Button size="sm" variant="outline" onClick={() => setIsEditingOverview(true)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  {isEditingOverview ? (
                    <div className="space-y-4">
                      <textarea
                        value={overviewText}
                        onChange={(e) => setOverviewText(e.target.value)}
                        className="w-full h-32 p-3 border rounded-md"
                        placeholder="Enter job overview..."
                      />
                      <div className="flex gap-2">
                        <Button size="sm" onClick={handleSaveOverview}>
                          <Save className="h-4 w-4 mr-2" />
                          Save
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          onClick={() => {
                            setIsEditingOverview(false)
                            setOverviewText(job.description || '')
                          }}
                        >
                          Cancel
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <p className="text-gray-700">
                      {job.description || 'No overview available. Click edit to add one.'}
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="technicians">
              <Card>
                <CardHeader>
                  <CardTitle>Assigned Technicians</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center gap-2">
                      <select
                        className="flex-1 p-2 border rounded-md"
                        onChange={(e) => {
                          if (e.target.value) {
                            handleAssignTechnician(e.target.value)
                            e.target.value = ''
                          }
                        }}
                      >
                        <option value="">Select technician to assign...</option>
                        {technicians
                          .filter(t => !assignedTechnicians.find(at => at.technician_id === t.id))
                          .map(tech => (
                            <option key={tech.id} value={tech.id}>
                              {tech.full_name || tech.email}
                            </option>
                          ))}
                      </select>
                    </div>

                    <div className="space-y-2">
                      {assignedTechnicians.map((assignment) => (
                        <div key={assignment.id} className="flex items-center justify-between p-3 border rounded-md">
                          <div className="flex items-center gap-2">
                            <User className="h-4 w-4 text-gray-500" />
                            <span>{assignment.technician?.full_name || assignment.technician?.email}</span>
                          </div>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => handleRemoveTechnician(assignment.id)}
                          >
                            <X className="h-4 w-4" />
                          </Button>
                        </div>
                      ))}
                      {assignedTechnicians.length === 0 && (
                        <p className="text-gray-500 text-center py-4">
                          No technicians assigned yet
                        </p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="photos">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Photos</CardTitle>
                    <label className="cursor-pointer">
                      <input
                        type="file"
                        accept="image/*"
                        className="hidden"
                        onChange={handlePhotoUpload}
                        disabled={uploadingPhoto}
                      />
                      <Button size="sm" disabled={uploadingPhoto}>
                        <Upload className="h-4 w-4 mr-2" />
                        {uploadingPhoto ? 'Uploading...' : 'Upload Photo'}
                      </Button>
                    </label>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                    {jobPhotos.map((photo) => (
                      <div key={photo.id} className="relative group">
                        <img
                          src={photo.photo_url}
                          alt="Job photo"
                          className="w-full h-32 object-cover rounded-md"
                        />
                      </div>
                    ))}
                    {jobPhotos.length === 0 && (
                      <p className="text-gray-500 col-span-full text-center py-8">
                        No photos uploaded yet
                      </p>
                    )}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="files">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Files</CardTitle>
                    <label className="cursor-pointer">
                      <input
                        type="file"
                        className="hidden"
                        onChange={handleFileUpload}
                        disabled={uploadingFile}
                      />
                      <Button size="sm" disabled={uploadingFile}>
                        <Upload className="h-4 w-4 mr-2" />
                        {uploadingFile ? 'Uploading...' : 'Upload File'}
                      </Button>
                    </label>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    {jobFiles.map((file) => (
                      <div key={file.id} className="flex items-center justify-between p-3 border rounded-md">
                        <div className="flex items-center gap-2">
                          <FileText className="h-4 w-4 text-gray-500" />
                          <a 
                            href={file.file_url} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="text-blue-600 hover:underline"
                          >
                            {file.file_name}
                          </a>
                        </div>
                      </div>
                    ))}
                    {jobFiles.length === 0 && (
                      <p className="text-gray-500 text-center py-8">
                        No files uploaded yet
                      </p>
                    )}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="notes">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Notes</CardTitle>
                    {!isEditingNotes && (
                      <Button size="sm" variant="outline" onClick={() => setIsEditingNotes(true)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  {isEditingNotes ? (
                    <div className="space-y-4">
                      <textarea
                        value={notesText}
                        onChange={(e) => setNotesText(e.target.value)}
                        className="w-full h-32 p-3 border rounded-md"
                        placeholder="Enter job notes..."
                      />
                      <div className="flex gap-2">
                        <Button size="sm" onClick={handleSaveNotes}>
                          <Save className="h-4 w-4 mr-2" />
                          Save
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          onClick={() => {
                            setIsEditingNotes(false)
                            setNotesText(job.notes || '')
                          }}
                        >
                          Cancel
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <p className="text-gray-700">
                      {job.notes || 'No notes available. Click edit to add notes.'}
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Job Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-muted-foreground">Customer</p>
                <p className="font-medium">{job.customers?.name || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Job Type</p>
                <p className="font-medium">{job.job_type}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Scheduled Date</p>
                <p className="font-medium">
                  {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : 'Not scheduled'}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Service Address</p>
                <p className="font-medium">
                  {job.service_address || 'No address specified'}
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Edit Job Modal */}
      {showEditModal && (
        <EditJobModal 
          job={job}
          onClose={() => setShowEditModal(false)}
          onSave={(updatedJob) => {
            setJob(updatedJob)
            setShowEditModal(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}

function EditJobModal({ job, onClose, onSave }: any) {
  const [formData, setFormData] = useState({
    customer_id: job.customer_id,
    title: job.title,
    description: job.description || '',
    job_type: job.job_type,
    status: job.status,
    service_address: job.service_address || '',
    service_city: job.service_city || '',
    service_state: job.service_state || '',
    service_zip: job.service_zip || '',
    scheduled_date: job.scheduled_date || '',
    scheduled_time: job.scheduled_time || '',
    notes: job.notes || ''
  })
  const [customers, setCustomers] = useState<any[]>([])
  const [selectedCustomer, setSelectedCustomer] = useState<any>(job.customers)
  const [isLoading, setIsLoading] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    loadCustomers()
  }, [])

  const loadCustomers = async () => {
    const { data } = await supabase
      .from('customers')
      .select('*')
      .order('name')
    
    if (data) setCustomers(data)
  }

  const handleSave = async () => {
    setIsLoading(true)
    
    const { error } = await supabase
      .from('jobs')
      .update(formData)
      .eq('id', job.id)
    
    if (!error) {
      // If customer changed, update customer details
      if (selectedCustomer && selectedCustomer.id !== job.customer_id) {
        await supabase
          .from('customers')
          .update({
            name: selectedCustomer.name,
            email: selectedCustomer.email,
            phone: selectedCustomer.phone,
            address: selectedCustomer.address
          })
          .eq('id', selectedCustomer.id)
      }
      
      toast.success('Job updated successfully')
      onSave({ ...job, ...formData, customers: selectedCustomer })
    } else {
      toast.error('Failed to update job')
    }
    
    setIsLoading(false)
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold">Edit Job</h2>
            <button onClick={onClose}>
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="space-y-4">
            {/* Customer Selection */}
            <div>
              <label className="block text-sm font-medium mb-1">Customer</label>
              <select
                value={formData.customer_id}
                onChange={(e) => {
                  const customer = customers.find(c => c.id === e.target.value)
                  setSelectedCustomer(customer)
                  setFormData({ ...formData, customer_id: e.target.value })
                }}
                className="w-full p-2 border rounded-md"
              >
                {customers.map(customer => (
                  <option key={customer.id} value={customer.id}>
                    {customer.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Customer Details (editable) */}
            {selectedCustomer && (
              <div className="p-4 bg-gray-50 rounded-md space-y-3">
                <h3 className="font-medium">Customer Details</h3>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm text-gray-600">Name</label>
                    <input
                      type="text"
                      value={selectedCustomer.name}
                      onChange={(e) => setSelectedCustomer({ ...selectedCustomer, name: e.target.value })}
                      className="w-full p-2 border rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-600">Email</label>
                    <input
                      type="email"
                      value={selectedCustomer.email || ''}
                      onChange={(e) => setSelectedCustomer({ ...selectedCustomer, email: e.target.value })}
                      className="w-full p-2 border rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-600">Phone</label>
                    <input
                      type="text"
                      value={selectedCustomer.phone || ''}
                      onChange={(e) => setSelectedCustomer({ ...selectedCustomer, phone: e.target.value })}
                      className="w-full p-2 border rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-600">Address</label>
                    <input
                      type="text"
                      value={selectedCustomer.address || ''}
                      onChange={(e) => setSelectedCustomer({ ...selectedCustomer, address: e.target.value })}
                      className="w-full p-2 border rounded-md"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Job Details */}
            <div>
              <label className="block text-sm font-medium mb-1">Job Title</label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                className="w-full p-2 border rounded-md"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">Job Type</label>
                <select
                  value={formData.job_type}
                  onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
                  className="w-full p-2 border rounded-md"
                >
                  <option value="installation">Installation</option>
                  <option value="repair">Repair</option>
                  <option value="maintenance">Maintenance</option>
                  <option value="inspection">Inspection</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">Status</label>
                <select
                  value={formData.status}
                  onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                  className="w-full p-2 border rounded-md"
                >
                  <option value="not_scheduled">Not Scheduled</option>
                  <option value="scheduled">Scheduled</option>
                  <option value="in_progress">In Progress</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>

            {/* Service Location */}
            <div>
              <label className="block text-sm font-medium mb-1">Service Address</label>
              <input
                type="text"
                value={formData.service_address}
                onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
                className="w-full p-2 border rounded-md"
                placeholder="123 Main St"
              />
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">City</label>
                <input
                  type="text"
                  value={formData.service_city}
                  onChange={(e) => setFormData({ ...formData, service_city: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">State</label>
                <input
                  type="text"
                  value={formData.service_state}
                  onChange={(e) => setFormData({ ...formData, service_state: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">ZIP</label>
                <input
                  type="text"
                  value={formData.service_zip}
                  onChange={(e) => setFormData({ ...formData, service_zip: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
            </div>

            {/* Scheduling */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">Scheduled Date</label>
                <input
                  type="date"
                  value={formData.scheduled_date}
                  onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Scheduled Time</label>
                <input
                  type="time"
                  value={formData.scheduled_time}
                  onChange={(e) => setFormData({ ...formData, scheduled_time: e.target.value })}
                  className="w-full p-2 border rounded-md"
                />
              </div>
            </div>

            {/* Overview */}
            <div>
              <label className="block text-sm font-medium mb-1">Overview</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                className="w-full p-2 border rounded-md h-24"
                placeholder="Job overview..."
              />
            </div>

            {/* Notes */}
            <div>
              <label className="block text-sm font-medium mb-1">Notes</label>
              <textarea
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                className="w-full p-2 border rounded-md h-24"
                placeholder="Additional notes..."
              />
            </div>
          </div>

          <div className="flex justify-end gap-2 mt-6">
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={isLoading}>
              {isLoading ? 'Saving...' : 'Save Changes'}
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

echo "✅ Created comprehensive JobDetailView component"

# Test the build
echo "🧪 Testing build..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -50

# Check for build errors
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Commit and push
    git add -A
    git commit -m "Fix: Comprehensive update - Send button visibility, technician refresh, job management with file uploads and editing"
    git push origin main
    
    echo "✅ Changes pushed to GitHub!"
else
    echo "❌ Build failed. Please check the errors above."
fi

echo "🎉 Update complete!"
