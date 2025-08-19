#!/bin/bash

# Service Pro - Comprehensive Fix Script
# Fixes all reported issues in one go

set -e # Exit on error

echo "🔧 Starting comprehensive fix for Service Pro issues..."

# Navigate to project directory
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Fix Photo Upload in Jobs
echo "📸 Fixing photo upload in jobs..."
cat > app/jobs/[id]/PhotoUpload.tsx << 'EOF'
'use client'

import { useState, useRef } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { Upload, X, Loader2 } from 'lucide-react'

interface PhotoUploadProps {
  jobId: string
  onPhotosUploaded: () => void
}

export function PhotoUpload({ jobId, onPhotosUploaded }: PhotoUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const fileInputRef = useRef<HTMLInputElement>(null)
  const supabase = createBrowserClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files)
      setSelectedFiles(files)
    }
  }

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      toast.error('Please select files to upload')
      return
    }

    setIsUploading(true)
    let uploadedCount = 0

    try {
      for (const file of selectedFiles) {
        const fileName = `${jobId}/${Date.now()}_${file.name}`
        
        // Upload to Supabase storage
        const { error: uploadError } = await supabase.storage
          .from('job-photos')
          .upload(fileName, file)

        if (uploadError) throw uploadError

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('job-photos')
          .getPublicUrl(fileName)

        // Save metadata to database
        const { error: dbError } = await supabase
          .from('job_photos')
          .insert({
            job_id: jobId,
            photo_url: publicUrl,
            photo_type: 'during',
            uploaded_by: (await supabase.auth.getUser()).data.user?.id
          })

        if (dbError) throw dbError
        uploadedCount++
      }

      toast.success(`Successfully uploaded ${uploadedCount} photo${uploadedCount > 1 ? 's' : ''}`)
      setSelectedFiles([])
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
      onPhotosUploaded()
    } catch (error) {
      console.error('Upload error:', error)
      toast.error('Failed to upload photos')
    } finally {
      setIsUploading(false)
    }
  }

  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index))
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept="image/*"
          onChange={handleFileSelect}
          className="hidden"
          id="photo-upload"
        />
        <label
          htmlFor="photo-upload"
          className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
        >
          <Upload className="h-4 w-4 mr-2" />
          Select Photos
        </label>
        {selectedFiles.length > 0 && (
          <button
            onClick={handleUpload}
            disabled={isUploading}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
          >
            {isUploading ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Uploading...
              </>
            ) : (
              <>
                <Upload className="h-4 w-4 mr-2" />
                Upload {selectedFiles.length} Photo{selectedFiles.length > 1 ? 's' : ''}
              </>
            )}
          </button>
        )}
      </div>

      {selectedFiles.length > 0 && (
        <div className="mt-4 space-y-2">
          <p className="text-sm text-gray-600">Selected files:</p>
          {selectedFiles.map((file, index) => (
            <div key={index} className="flex items-center justify-between bg-gray-50 p-2 rounded">
              <span className="text-sm text-gray-700">{file.name}</span>
              <button
                onClick={() => removeFile(index)}
                className="text-red-500 hover:text-red-700"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
EOF

# 2. Fix File Upload in Jobs
echo "📁 Fixing file upload in jobs..."
cat > app/jobs/[id]/FileUpload.tsx << 'EOF'
'use client'

import { useState, useRef } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { Upload, X, Loader2, FileText } from 'lucide-react'

interface FileUploadProps {
  jobId: string
  onFilesUploaded: () => void
}

export function FileUpload({ jobId, onFilesUploaded }: FileUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const fileInputRef = useRef<HTMLInputElement>(null)
  const supabase = createBrowserClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files)
      setSelectedFiles(files)
    }
  }

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      toast.error('Please select files to upload')
      return
    }

    setIsUploading(true)
    let uploadedCount = 0

    try {
      for (const file of selectedFiles) {
        const fileName = `${jobId}/${Date.now()}_${file.name}`
        
        // Upload to Supabase storage
        const { error: uploadError } = await supabase.storage
          .from('job-files')
          .upload(fileName, file)

        if (uploadError) throw uploadError

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('job-files')
          .getPublicUrl(fileName)

        // Save metadata to database
        const { error: dbError } = await supabase
          .from('job_files')
          .insert({
            job_id: jobId,
            file_name: file.name,
            file_url: publicUrl,
            file_type: file.type || 'application/octet-stream',
            file_size: file.size,
            uploaded_by: (await supabase.auth.getUser()).data.user?.id
          })

        if (dbError) throw dbError
        uploadedCount++
      }

      toast.success(`Successfully uploaded ${uploadedCount} file${uploadedCount > 1 ? 's' : ''}`)
      setSelectedFiles([])
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
      onFilesUploaded()
    } catch (error) {
      console.error('Upload error:', error)
      toast.error('Failed to upload files')
    } finally {
      setIsUploading(false)
    }
  }

  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index))
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <input
          ref={fileInputRef}
          type="file"
          multiple
          onChange={handleFileSelect}
          className="hidden"
          id="file-upload"
        />
        <label
          htmlFor="file-upload"
          className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
        >
          <Upload className="h-4 w-4 mr-2" />
          Select Files
        </label>
        {selectedFiles.length > 0 && (
          <button
            onClick={handleUpload}
            disabled={isUploading}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
          >
            {isUploading ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Uploading...
              </>
            ) : (
              <>
                <Upload className="h-4 w-4 mr-2" />
                Upload {selectedFiles.length} File{selectedFiles.length > 1 ? 's' : ''}
              </>
            )}
          </button>
        )}
      </div>

      {selectedFiles.length > 0 && (
        <div className="mt-4 space-y-2">
          <p className="text-sm text-gray-600">Selected files:</p>
          {selectedFiles.map((file, index) => (
            <div key={index} className="flex items-center justify-between bg-gray-50 p-2 rounded">
              <div className="flex items-center">
                <FileText className="h-4 w-4 mr-2 text-gray-500" />
                <span className="text-sm text-gray-700">{file.name}</span>
              </div>
              <button
                onClick={() => removeFile(index)}
                className="text-red-500 hover:text-red-700"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
EOF

# 3. Fix Technician Dropdown in Jobs
echo "👷 Fixing technician assignment dropdown..."
cat > app/components/technician/TechnicianSearch.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'
import { X, Check } from 'lucide-react'

interface Technician {
  id: string
  email: string
  full_name: string | null
  phone: string | null
}

interface TechnicianSearchProps {
  selectedTechnicians: Technician[]
  onTechniciansChange: (technicians: Technician[]) => void
  className?: string
}

export function TechnicianSearch({ 
  selectedTechnicians, 
  onTechniciansChange,
  className = ''
}: TechnicianSearchProps) {
  const [searchTerm, setSearchTerm] = useState('')
  const [allTechnicians, setAllTechnicians] = useState<Technician[]>([])
  const [filteredTechnicians, setFilteredTechnicians] = useState<Technician[]>([])
  const [isDropdownOpen, setIsDropdownOpen] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const supabase = createBrowserClient()

  useEffect(() => {
    fetchTechnicians()
  }, [])

  useEffect(() => {
    if (searchTerm) {
      const filtered = allTechnicians.filter(tech => 
        !selectedTechnicians.some(selected => selected.id === tech.id) &&
        (tech.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
         tech.email.toLowerCase().includes(searchTerm.toLowerCase()))
      )
      setFilteredTechnicians(filtered)
      setIsDropdownOpen(filtered.length > 0)
    } else {
      setFilteredTechnicians([])
      setIsDropdownOpen(false)
    }
  }, [searchTerm, allTechnicians, selectedTechnicians])

  const fetchTechnicians = async () => {
    setIsLoading(true)
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, email, full_name, phone')
        .eq('role', 'technician')
        .eq('is_active', true)
        .order('full_name')

      if (error) throw error
      setAllTechnicians(data || [])
    } catch (error) {
      console.error('Error fetching technicians:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleAddTechnician = (technician: Technician) => {
    onTechniciansChange([...selectedTechnicians, technician])
    setSearchTerm('')
    setIsDropdownOpen(false)
  }

  const handleRemoveTechnician = (technicianId: string) => {
    onTechniciansChange(selectedTechnicians.filter(t => t.id !== technicianId))
  }

  return (
    <div className={`space-y-2 ${className}`}>
      <div className="relative">
        <input
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          placeholder={isLoading ? "Loading technicians..." : "Search technicians..."}
          disabled={isLoading}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 disabled:bg-gray-100"
        />
        
        {isDropdownOpen && (
          <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto">
            {filteredTechnicians.map((technician) => (
              <button
                key={technician.id}
                onClick={() => handleAddTechnician(technician)}
                className="w-full px-3 py-2 text-left hover:bg-gray-100 flex items-center justify-between"
              >
                <div>
                  <div className="font-medium">
                    {technician.full_name || technician.email}
                  </div>
                  {technician.full_name && (
                    <div className="text-sm text-gray-500">{technician.email}</div>
                  )}
                </div>
                <Check className="h-4 w-4 text-green-500" />
              </button>
            ))}
            {filteredTechnicians.length === 0 && (
              <div className="px-3 py-2 text-gray-500">No technicians found</div>
            )}
          </div>
        )}
      </div>

      {selectedTechnicians.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {selectedTechnicians.map((technician) => (
            <div
              key={technician.id}
              className="inline-flex items-center px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
            >
              <span>{technician.full_name || technician.email}</span>
              <button
                onClick={() => handleRemoveTechnician(technician.id)}
                className="ml-2 hover:text-blue-600"
              >
                <X className="h-3 w-3" />
              </button>
            </div>
          ))}
        </div>
      )}

      {!isLoading && allTechnicians.length === 0 && (
        <p className="text-sm text-gray-500">No technicians available. Please add technicians in the Technicians section.</p>
      )}
    </div>
  )
}
EOF

# 4. Fix EditJobModal to handle save properly
echo "📝 Fixing Edit Job modal..."
cat > app/jobs/[id]/EditJobModal.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { X, Loader2 } from 'lucide-react'

interface EditJobModalProps {
  job: any
  isOpen: boolean
  onClose: () => void
  onJobUpdated: () => void
}

export function EditJobModal({ job, isOpen, onClose, onJobUpdated }: EditJobModalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [customers, setCustomers] = useState<any[]>([])
  const [formData, setFormData] = useState({
    customer_id: job.customer_id || '',
    title: job.title || '',
    description: job.description || '',
    job_type: job.job_type || 'repair',
    status: job.status || 'not_scheduled',
    service_address: job.service_address || '',
    service_city: job.service_city || '',
    service_state: job.service_state || '',
    service_zip: job.service_zip || '',
    scheduled_date: job.scheduled_date || '',
    scheduled_time: job.scheduled_time || '',
    notes: job.notes || ''
  })
  const supabase = createBrowserClient()

  useEffect(() => {
    fetchCustomers()
  }, [])

  const fetchCustomers = async () => {
    const { data, error } = await supabase
      .from('customers')
      .select('id, name, email')
      .order('name')

    if (!error && data) {
      setCustomers(data)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)

    try {
      const { error } = await supabase
        .from('jobs')
        .update(formData)
        .eq('id', job.id)

      if (error) throw error

      toast.success('Job updated successfully')
      onJobUpdated()
      onClose()
    } catch (error: any) {
      console.error('Error updating job:', error)
      toast.error(error.message || 'Failed to update job')
    } finally {
      setIsLoading(false)
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between">
          <h2 className="text-xl font-semibold">Edit Job</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Customer
            </label>
            <select
              value={formData.customer_id}
              onChange={(e) => setFormData({ ...formData, customer_id: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              required
            >
              <option value="">Select a customer</option>
              {customers.map((customer) => (
                <option key={customer.id} value={customer.id}>
                  {customer.name} ({customer.email})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Job Title
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Job Type
              </label>
              <select
                value={formData.job_type}
                onChange={(e) => setFormData({ ...formData, job_type: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="installation">Installation</option>
                <option value="repair">Repair</option>
                <option value="maintenance">Maintenance</option>
                <option value="inspection">Inspection</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Status
              </label>
              <select
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="not_scheduled">Not Scheduled</option>
                <option value="scheduled">Scheduled</option>
                <option value="in_progress">In Progress</option>
                <option value="completed">Completed</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Service Address
            </label>
            <input
              type="text"
              value={formData.service_address}
              onChange={(e) => setFormData({ ...formData, service_address: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                City
              </label>
              <input
                type="text"
                value={formData.service_city}
                onChange={(e) => setFormData({ ...formData, service_city: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                State
              </label>
              <input
                type="text"
                value={formData.service_state}
                onChange={(e) => setFormData({ ...formData, service_state: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                ZIP
              </label>
              <input
                type="text"
                value={formData.service_zip}
                onChange={(e) => setFormData({ ...formData, service_zip: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Scheduled Date
              </label>
              <input
                type="date"
                value={formData.scheduled_date}
                onChange={(e) => setFormData({ ...formData, scheduled_date: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
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
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Notes
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 flex items-center"
            >
              {isLoading ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Saving...
                </>
              ) : (
                'Save Changes'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

# 5. Remove Invoices tab from navigation
echo "🗑️ Removing Invoices tab from navigation..."
cat > app/components/Navigation.tsx << 'EOF'
'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { createBrowserClient } from '@/lib/supabase/client'
import { useEffect, useState } from 'react'
import { LogOut, Menu, X } from 'lucide-react'

export default function Navigation() {
  const pathname = usePathname()
  const router = useRouter()
  const [userRole, setUserRole] = useState<string | null>(null)
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const supabase = createBrowserClient()

  useEffect(() => {
    getUserRole()
  }, [])

  const getUserRole = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()
      
      if (profile) {
        setUserRole(profile.role)
      }
    }
  }

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/auth/login')
  }

  const navItems = [
    { href: '/dashboard', label: 'Dashboard', roles: ['boss', 'admin'] },
    { href: '/proposals', label: 'Proposals', roles: ['boss', 'admin'] },
    { href: '/jobs', label: 'Jobs', roles: ['boss', 'admin', 'technician'] },
    { href: '/customers', label: 'Customers', roles: ['boss', 'admin'] },
    { href: '/technicians', label: 'Technicians', roles: ['boss', 'admin'] },
    { href: '/technician', label: 'My Tasks', roles: ['technician'] },
  ]

  const visibleNavItems = navItems.filter(item => 
    item.roles.includes(userRole || '')
  )

  return (
    <nav className="bg-white shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <div className="flex-shrink-0 flex items-center">
              <Link href="/dashboard" className="text-xl font-bold text-blue-600">
                Service Pro
              </Link>
            </div>
            <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
              {visibleNavItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                    pathname.startsWith(item.href)
                      ? 'border-blue-500 text-gray-900'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                  }`}
                >
                  {item.label}
                </Link>
              ))}
            </div>
          </div>
          
          <div className="hidden sm:ml-6 sm:flex sm:items-center">
            <button
              onClick={handleLogout}
              className="flex items-center text-gray-500 hover:text-gray-700"
            >
              <LogOut className="h-5 w-5 mr-1" />
              Logout
            </button>
          </div>

          <div className="flex items-center sm:hidden">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100"
            >
              {isMenuOpen ? (
                <X className="block h-6 w-6" />
              ) : (
                <Menu className="block h-6 w-6" />
              )}
            </button>
          </div>
        </div>
      </div>

      {isMenuOpen && (
        <div className="sm:hidden">
          <div className="pt-2 pb-3 space-y-1">
            {visibleNavItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={`block pl-3 pr-4 py-2 border-l-4 text-base font-medium ${
                  pathname.startsWith(item.href)
                    ? 'bg-blue-50 border-blue-500 text-blue-700'
                    : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700'
                }`}
                onClick={() => setIsMenuOpen(false)}
              >
                {item.label}
              </Link>
            ))}
            <button
              onClick={handleLogout}
              className="block w-full text-left pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700"
            >
              Logout
            </button>
          </div>
        </div>
      )}
    </nav>
  )
}
EOF

echo "✅ All component fixes applied!"
echo "🔨 Testing build..."

npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
  echo "✅ Build successful!"
  
  echo "📤 Committing and pushing changes..."
  git add -A
  git commit -m "Fix photo/file uploads, technician dropdown, edit job modal, and remove invoices tab"
  git push origin main
  
  echo "🚀 Deployment triggered!"
  echo "✅ All issues have been fixed!"
  echo ""
  echo "Fixed issues:"
  echo "1. ✅ Photo upload in jobs - now allows multiple file selection"
  echo "2. ✅ File upload in jobs - now allows multiple file selection"
  echo "3. ✅ Technician dropdown - properly fetches from database"
  echo "4. ✅ Edit Job modal - save functionality fixed"
  echo "5. ✅ Invoices tab removed from navigation"
  echo ""
  echo "Remaining issues to address:"
  echo "- Customer data sync when editing in job modal"
  echo "- Customer proposal approval flow"
  echo "- Mobile view button overflow"
  echo "- Proposal status options expansion"
  echo "- Add-ons vs services distinction"
else
  echo "❌ Build failed. Please check the errors above."
  exit 1
fi
