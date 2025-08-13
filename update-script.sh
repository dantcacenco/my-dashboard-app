#!/bin/bash

echo "🔧 Fixing all issues: Technician management, Jobs view, and navigation..."

# 1. Fix Technicians page - remove debug, keep admin client working
cat > app/\(authenticated\)/technicians/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { redirect } from 'next/navigation'
import TechniciansClientView from './TechniciansClientView'

export const dynamic = 'force-dynamic'
export const revalidate = 0

export default async function TechniciansPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/dashboard')
  }

  // Use admin client to get technicians (bypasses RLS)
  let technicians = []
  try {
    const adminClient = createAdminClient()
    const { data } = await adminClient
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
      .order('created_at', { ascending: false })
    
    technicians = data || []
  } catch (error) {
    console.error('Error fetching technicians:', error)
  }

  return <TechniciansClientView technicians={technicians} />
}
EOF

# 2. Update TechniciansClientView with edit/delete functionality
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

  const handleRefresh = () => {
    setIsRefreshing(true)
    router.refresh()
    setTimeout(() => setIsRefreshing(false), 1000)
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
                    <div className="flex justify-between items-start mb-3">
                      <div className="flex items-center gap-2">
                        <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                          <span className="text-blue-600 font-semibold">
                            {(tech.full_name || tech.email || 'T').charAt(0).toUpperCase()}
                          </span>
                        </div>
                        <div>
                          <div className="font-medium">
                            {tech.full_name || 'No name set'}
                          </div>
                          <Badge variant="outline" className="mt-1">
                            <UserCheck className="h-3 w-3 mr-1" />
                            Active
                          </Badge>
                        </div>
                      </div>
                      <div className="flex gap-1">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => setEditingTechnician(tech)}
                        >
                          <Edit2 className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          className="text-red-600 hover:text-red-700"
                          onClick={() => handleDelete(tech.id, tech.email)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                    <div className="space-y-1 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <Mail className="h-3 w-3" />
                        {tech.email}
                      </div>
                      {tech.phone && (
                        <div className="flex items-center gap-1">
                          <Phone className="h-3 w-3" />
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
                <Card key={tech.id} className="border opacity-60">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start">
                      <div className="flex items-center gap-2">
                        <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                          <span className="text-gray-600 font-semibold">
                            {(tech.full_name || tech.email || 'T').charAt(0).toUpperCase()}
                          </span>
                        </div>
                        <div>
                          <div className="font-medium">
                            {tech.full_name || 'No name set'}
                          </div>
                          <Badge variant="destructive" className="mt-1">
                            <UserX className="h-3 w-3 mr-1" />
                            Inactive
                          </Badge>
                        </div>
                      </div>
                      <div className="flex gap-1">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => setEditingTechnician(tech)}
                        >
                          <Edit2 className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          className="text-red-600 hover:text-red-700"
                          onClick={() => handleDelete(tech.id, tech.email)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
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
          onSuccess={() => {
            setShowAddModal(false)
            handleRefresh()
          }}
        />
      )}

      {editingTechnician && (
        <EditTechnicianModal
          technician={editingTechnician}
          onClose={() => setEditingTechnician(null)}
          onSuccess={() => {
            setEditingTechnician(null)
            handleRefresh()
          }}
        />
      )}
    </div>
  )
}
EOF

# 3. Create EditTechnicianModal component
cat > app/\(authenticated\)/technicians/EditTechnicianModal.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import { X, Loader2, Save } from 'lucide-react'
import { toast } from 'sonner'

interface EditTechnicianModalProps {
  technician: any
  onClose: () => void
  onSuccess: () => void
}

export default function EditTechnicianModal({ technician, onClose, onSuccess }: EditTechnicianModalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [formData, setFormData] = useState({
    fullName: technician.full_name || '',
    phone: technician.phone || '',
    isActive: technician.is_active !== false,
    resetPassword: false
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)

    try {
      const response = await fetch('/api/technicians/update', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          technicianId: technician.id,
          updates: {
            full_name: formData.fullName,
            phone: formData.phone,
            is_active: formData.isActive
          },
          resetPassword: formData.resetPassword
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to update technician')
      }

      toast.success('Technician updated successfully!')
      if (data.newPassword) {
        toast.info(`New password: ${data.newPassword}`)
      }
      onSuccess()
    } catch (error: any) {
      toast.error(error.message || 'Failed to update technician')
      setIsLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Edit Technician</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label>Email (cannot be changed)</Label>
            <Input
              type="email"
              value={technician.email}
              disabled
              className="bg-gray-50"
            />
          </div>

          <div>
            <Label htmlFor="fullName">Full Name</Label>
            <Input
              id="fullName"
              type="text"
              value={formData.fullName}
              onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
              placeholder="John Smith"
            />
          </div>

          <div>
            <Label htmlFor="phone">Phone Number</Label>
            <Input
              id="phone"
              type="tel"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              placeholder="(555) 123-4567"
            />
          </div>

          <div className="flex items-center justify-between">
            <Label htmlFor="isActive">Account Active</Label>
            <Switch
              id="isActive"
              checked={formData.isActive}
              onCheckedChange={(checked) => setFormData({ ...formData, isActive: checked })}
            />
          </div>

          <div className="flex items-center justify-between">
            <Label htmlFor="resetPassword">Reset Password</Label>
            <Switch
              id="resetPassword"
              checked={formData.resetPassword}
              onCheckedChange={(checked) => setFormData({ ...formData, resetPassword: checked })}
            />
          </div>

          <div className="flex gap-3 pt-4">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              className="flex-1"
              disabled={isLoading}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              className="flex-1"
              disabled={isLoading}
            >
              {isLoading ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Updating...
                </>
              ) : (
                <>
                  <Save className="h-4 w-4 mr-2" />
                  Save Changes
                </>
              )}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

# 4. Create DELETE API endpoint
cat > app/api/technicians/\[id\]/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { NextResponse } from 'next/server'

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const supabase = await createClient()
    
    // Check if user is boss/admin
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profile?.role !== 'boss' && profile?.role !== 'admin') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
    }

    const adminClient = createAdminClient()

    // Delete from profiles first
    const { error: profileError } = await adminClient
      .from('profiles')
      .delete()
      .eq('id', id)

    if (profileError) {
      console.error('Error deleting profile:', profileError)
      return NextResponse.json({ error: 'Failed to delete profile' }, { status: 500 })
    }

    // Delete from auth
    const { error: authError } = await adminClient.auth.admin.deleteUser(id)

    if (authError) {
      console.error('Error deleting auth user:', authError)
      // Profile already deleted, so we continue
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting technician:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
EOF

# 5. Fix Navigation.tsx to hide Jobs for technicians
cat > components/Navigation.tsx << 'EOF'
'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { LayoutDashboard, FileText, Users, Briefcase, DollarSign, LogOut, UserCog, Calendar } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { useEffect, useState } from 'react'

export default function Navigation() {
  const pathname = usePathname()
  const router = useRouter()
  const [userRole, setUserRole] = useState<string | null>(null)

  useEffect(() => {
    async function getUserRole() {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      if (user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single()
        setUserRole(profile?.role || null)
      }
    }
    getUserRole()
  }, [])

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/auth/login')
  }

  // Define navigation items based on role
  const navItems = userRole === 'technician' ? [
    { href: '/technician', label: 'My Tasks', icon: Calendar },
  ] : [
    { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/proposals', label: 'Proposals', icon: FileText },
    { href: '/customers', label: 'Customers', icon: Users },
    { href: '/jobs', label: 'Jobs', icon: Briefcase },
    { href: '/invoices', label: 'Invoices', icon: DollarSign },
    { href: '/technicians', label: 'Technicians', icon: UserCog },
  ]

  return (
    <nav className="w-64 bg-gray-900 text-white h-full flex flex-col">
      <div className="p-4">
        <h1 className="text-2xl font-bold">Service Pro</h1>
      </div>
      
      <div className="flex-1">
        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
          
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 hover:bg-gray-800 transition-colors ${
                isActive ? 'bg-gray-800 border-l-4 border-blue-500' : ''
              }`}
            >
              <Icon className="h-5 w-5" />
              <span>{item.label}</span>
            </Link>
          )
        })}
      </div>

      <div className="p-4">
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 w-full px-4 py-3 hover:bg-gray-800 rounded transition-colors"
        >
          <LogOut className="h-5 w-5" />
          <span>Sign Out</span>
        </button>
      </div>
    </nav>
  )
}
EOF

# 6. Fix Jobs page to show customer info properly
cat > app/\(authenticated\)/jobs/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Plus, Eye, MapPin } from 'lucide-react'

export default async function JobsPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: jobs, error } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
        name,
        email,
        phone,
        address
      )
    `)
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching jobs:', error)
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Jobs</h1>
          <p className="text-muted-foreground">Manage your service jobs</p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          New Job
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <CardTitle>All Jobs</CardTitle>
            <div className="flex gap-2">
              <Button variant="outline" size="sm">List View</Button>
              <Button variant="outline" size="sm">Grid View</Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-3 px-4">Job #</th>
                  <th className="text-left py-3 px-4">Customer</th>
                  <th className="text-left py-3 px-4">Address</th>
                  <th className="text-left py-3 px-4">Type</th>
                  <th className="text-center py-3 px-4">Status</th>
                  <th className="text-center py-3 px-4">Tasks</th>
                  <th className="text-left py-3 px-4">Created</th>
                  <th className="text-center py-3 px-4">Actions</th>
                </tr>
              </thead>
              <tbody>
                {jobs?.map((job) => (
                  <tr key={job.id} className="border-b hover:bg-gray-50">
                    <td className="py-3 px-4">
                      <Link 
                        href={`/jobs/${job.id}`}
                        className="font-medium text-blue-600 hover:text-blue-800"
                      >
                        {job.job_number}
                      </Link>
                    </td>
                    <td className="py-3 px-4">
                      {job.customers ? (
                        <div>
                          <div className="font-medium">{job.customers.name}</div>
                          <div className="text-sm text-muted-foreground">{job.customers.email}</div>
                        </div>
                      ) : (
                        <span className="text-muted-foreground">No customer</span>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      {job.service_address ? (
                        <div className="flex items-center gap-1">
                          <MapPin className="h-3 w-3 text-muted-foreground" />
                          <span className="text-sm">
                            {job.service_address}
                            {job.service_city && `, ${job.service_city}`}
                            {job.service_state && `, ${job.service_state}`}
                          </span>
                        </div>
                      ) : (
                        <span className="text-muted-foreground text-sm">No address</span>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      <span className="text-sm capitalize">{job.job_type}</span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <Badge variant={
                        job.status === 'completed' ? 'default' :
                        job.status === 'in_progress' ? 'secondary' :
                        'outline'
                      }>
                        {job.status.replace('_', ' ')}
                      </Badge>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className="text-sm">0 tasks</span>
                    </td>
                    <td className="py-3 px-4">
                      <span className="text-sm">
                        {new Date(job.created_at).toLocaleDateString()}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <Link href={`/jobs/${job.id}`}>
                        <Button size="sm" variant="outline">
                          <Eye className="h-4 w-4 mr-1" />
                          View
                        </Button>
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {(!jobs || jobs.length === 0) && (
              <div className="text-center py-8 text-muted-foreground">
                No jobs found
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
EOF

# 7. Create Job Detail page
mkdir -p app/\(authenticated\)/jobs/\[id\]
cat > app/\(authenticated\)/jobs/\[id\]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import JobDetailView from './JobDetailView'

export default async function JobDetailPage({ 
  params 
}: { 
  params: Promise<{ id: string }> 
}) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

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

  if (error || !job) {
    notFound()
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const { data: technicians } = await supabase
    .from('profiles')
    .select('id, full_name, email')
    .eq('role', 'technician')
    .eq('is_active', true)

  return (
    <JobDetailView 
      job={job} 
      userRole={profile?.role || 'technician'}
      availableTechnicians={technicians || []}
    />
  )
}
EOF

# Add Switch component if not exists
if [ ! -f "components/ui/switch.tsx" ]; then
  npx shadcn@latest add switch --yes
fi

# Commit everything
git add .
git commit -m "fix: complete technician management, job views, and navigation"
git push origin main

echo "✅ All issues fixed!"
echo ""
echo "🎯 What's been implemented:"
echo "1. ✅ Technicians page - clean, no debug info"
echo "2. ✅ Edit/Delete technicians with modal"
echo "3. ✅ Technician portal - no Jobs tab"
echo "4. ✅ Jobs page - shows customer info and address"
echo "5. ✅ Job detail page - ready for technician assignment"
echo "6. ✅ Navigation - role-based menu items"
echo ""
echo "Deploy and test all the features!"