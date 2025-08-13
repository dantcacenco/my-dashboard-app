#!/bin/bash

echo "🔧 Fixing technician display issue..."

# First, let's create a debug script to check the database
cat > check-technicians.sql << 'SQLEOF'
-- Check auth users and profiles
SELECT 
  'Auth Users' as source,
  au.id,
  au.email,
  au.created_at,
  au.user_metadata->>'full_name' as full_name,
  au.user_metadata->>'role' as role
FROM auth.users au
ORDER BY au.created_at DESC;

-- Check profiles table
SELECT 
  'Profiles' as source,
  p.id,
  p.email,
  p.full_name,
  p.role,
  p.is_active,
  p.created_at
FROM profiles p
ORDER BY p.created_at DESC;

-- Check for orphaned auth users (no profile)
SELECT 
  'Orphaned Auth Users (no profile)' as issue,
  au.id,
  au.email,
  au.created_at
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- Check for technicians specifically
SELECT 
  'Technicians in Profiles' as category,
  COUNT(*) as count
FROM profiles
WHERE role = 'technician';
SQLEOF

echo "✅ Created check-technicians.sql - Run this in Supabase SQL Editor to diagnose"
echo ""

# Now fix the TechniciansView to properly refresh
cat > app/\(authenticated\)/technicians/TechniciansView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Plus, Edit, UserCheck, UserX, Phone, Mail, RefreshCw } from 'lucide-react'
import AddTechnicianModal from './AddTechnicianModal'
import { createClient } from '@/lib/supabase/client'

interface Technician {
  id: string
  email: string
  full_name: string | null
  phone: string | null
  is_active?: boolean
  created_at: string
}

export default function TechniciansView({ technicians: initialTechnicians }: { technicians: Technician[] }) {
  const [technicians, setTechnicians] = useState(initialTechnicians)
  const [showAddModal, setShowAddModal] = useState(false)
  const [selectedTechnician, setSelectedTechnician] = useState<Technician | null>(null)
  const [isRefreshing, setIsRefreshing] = useState(false)
  const router = useRouter()

  // Function to refresh technicians list
  const refreshTechnicians = async () => {
    setIsRefreshing(true)
    try {
      const supabase = createClient()
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'technician')
        .order('full_name', { ascending: true })

      if (!error && data) {
        setTechnicians(data)
      }
    } catch (error) {
      console.error('Error refreshing technicians:', error)
    } finally {
      setIsRefreshing(false)
    }
  }

  const handleTechnicianCreated = async () => {
    setShowAddModal(false)
    // Wait a moment for the database to update
    setTimeout(() => {
      refreshTechnicians()
      router.refresh()
    }, 1000)
  }

  const activeTechnicians = technicians.filter(t => t.is_active !== false)
  const inactiveTechnicians = technicians.filter(t => t.is_active === false)

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">Technicians</h1>
          <p className="text-muted-foreground">Manage your field technicians</p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="icon"
            onClick={refreshTechnicians}
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
                            {tech.full_name?.charAt(0) || tech.email.charAt(0).toUpperCase()}
                          </span>
                        </div>
                        <div>
                          <div className="font-medium">{tech.full_name || 'No name'}</div>
                          <Badge variant="outline" className="mt-1">
                            <UserCheck className="h-3 w-3 mr-1" />
                            Active
                          </Badge>
                        </div>
                      </div>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => setSelectedTechnician(tech)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
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
                      <div className="text-xs text-gray-400 mt-2">
                        ID: {tech.id.slice(0, 8)}...
                      </div>
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
                    <div className="flex items-center gap-2">
                      <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                        <span className="text-gray-600 font-semibold">
                          {tech.full_name?.charAt(0) || tech.email.charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <div>
                        <div className="font-medium">{tech.full_name || 'No name'}</div>
                        <Badge variant="destructive" className="mt-1">
                          <UserX className="h-3 w-3 mr-1" />
                          Inactive
                        </Badge>
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
          onSuccess={handleTechnicianCreated}
        />
      )}
    </div>
  )
}
EOF

# Create a sync technicians API endpoint to fix orphaned users
cat > app/api/technicians/fix-orphaned/route.ts << 'EOF'
import { createAdminClient } from '@/lib/supabase/admin'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

/**
 * Fix orphaned auth users that don't have profiles
 */
export async function POST(request: Request) {
  try {
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

    // Get all auth users
    const { data: { users }, error: listError } = await adminClient.auth.admin.listUsers()

    if (listError) {
      return NextResponse.json({ 
        error: 'Failed to list auth users' 
      }, { status: 500 })
    }

    const fixedUsers = []
    const errors = []

    for (const authUser of users) {
      // Check if profile exists
      const { data: existingProfile } = await adminClient
        .from('profiles')
        .select('id')
        .eq('id', authUser.id)
        .single()

      if (!existingProfile && authUser.email) {
        // Create missing profile
        const { data: newProfile, error: createError } = await adminClient
          .from('profiles')
          .insert({
            id: authUser.id,
            email: authUser.email,
            full_name: authUser.user_metadata?.full_name || authUser.email.split('@')[0],
            role: authUser.user_metadata?.role || 'technician',
            is_active: true
          })
          .select()
          .single()

        if (createError) {
          errors.push({
            userId: authUser.id,
            email: authUser.email,
            error: createError.message
          })
        } else {
          fixedUsers.push({
            userId: authUser.id,
            email: authUser.email,
            full_name: newProfile?.full_name
          })
        }
      }
    }

    return NextResponse.json({ 
      success: true,
      message: `Fixed ${fixedUsers.length} orphaned users`,
      fixedUsers,
      errors,
      totalAuthUsers: users.length
    })

  } catch (error) {
    console.error('Error fixing orphaned users:', error)
    return NextResponse.json({ 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}
EOF

# Create a manual fix button component
cat > app/\(authenticated\)/technicians/FixOrphanedButton.tsx << 'EOF'
'use client'

import { Button } from '@/components/ui/button'
import { Wrench, Loader2 } from 'lucide-react'
import { useState } from 'react'
import { toast } from 'sonner'
import { useRouter } from 'next/navigation'

export default function FixOrphanedButton() {
  const [isFixing, setIsFixing] = useState(false)
  const router = useRouter()

  const handleFix = async () => {
    setIsFixing(true)
    try {
      const response = await fetch('/api/technicians/fix-orphaned', {
        method: 'POST'
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to fix orphaned users')
      }

      if (data.fixedUsers.length > 0) {
        toast.success(`Fixed ${data.fixedUsers.length} orphaned technician(s)`)
        router.refresh()
      } else {
        toast.info('No orphaned technicians found')
      }

      console.log('Fix results:', data)
    } catch (error: any) {
      toast.error(error.message || 'Failed to fix orphaned users')
    } finally {
      setIsFixing(false)
    }
  }

  return (
    <Button
      variant="outline"
      size="sm"
      onClick={handleFix}
      disabled={isFixing}
    >
      {isFixing ? (
        <>
          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
          Fixing...
        </>
      ) : (
        <>
          <Wrench className="h-4 w-4 mr-2" />
          Fix Missing Profiles
        </>
      )}
    </Button>
  )
}
EOF

# Update technicians page to include the fix button
cat > app/\(authenticated\)/technicians/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechniciansView from './TechniciansView'
import FixOrphanedButton from './FixOrphanedButton'

export default async function TechniciansPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only boss/admin can manage technicians
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/dashboard')
  }

  const { data: technicians } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'technician')
    .order('full_name', { ascending: true })

  return (
    <>
      <div className="p-6 pb-0">
        <div className="flex justify-end">
          <FixOrphanedButton />
        </div>
      </div>
      <TechniciansView technicians={technicians || []} />
    </>
  )
}
EOF

# Commit the fix
git add .
git commit -m "fix: technician not appearing in list - add profile sync and refresh"
git push origin main

echo "✅ Fix implemented!"
echo ""
echo "📋 IMMEDIATE ACTIONS:"
echo ""
echo "1. Run the SQL in check-technicians.sql in Supabase to see the current state"
echo ""
echo "2. After deployment, go to /technicians and click 'Fix Missing Profiles' button"
echo "   This will create profiles for any auth users missing them"
echo ""
echo "3. The page now has a refresh button to manually reload the list"
echo ""
echo "The issue was likely that the auth user was created but the profile wasn't."
echo "The fix button will sync them up!"