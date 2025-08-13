#!/bin/bash

echo "🔐 Setting up full auth user creation with Supabase Admin API..."

# Step 1: Create admin client utility
mkdir -p lib/supabase
cat > lib/supabase/admin.ts << 'EOF'
import { createClient } from '@supabase/supabase-js'

/**
 * Creates a Supabase Admin client with service role privileges
 * WARNING: This should ONLY be used in server-side code (API routes, server components)
 * NEVER expose this to the client side
 */
export function createAdminClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    throw new Error('Missing Supabase environment variables')
  }

  return createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  })
}
EOF

# Step 2: Update the create technician API with full auth
cat > app/api/technicians/create/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    // Regular client for checking current user
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

    const { email, password, full_name, phone } = await request.json()

    // Validate input
    if (!email || !password || !full_name) {
      return NextResponse.json({ 
        error: 'Email, password, and full name are required' 
      }, { status: 400 })
    }

    if (password.length < 6) {
      return NextResponse.json({ 
        error: 'Password must be at least 6 characters' 
      }, { status: 400 })
    }

    // Create admin client for user creation
    const adminClient = createAdminClient()

    // Create the auth user
    const { data: authData, error: authError } = await adminClient.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        full_name: full_name,
        role: 'technician'
      }
    })

    if (authError) {
      console.error('Error creating auth user:', authError)
      
      // Check if user already exists
      if (authError.message?.includes('already registered')) {
        return NextResponse.json({ 
          error: 'A user with this email already exists' 
        }, { status: 400 })
      }
      
      return NextResponse.json({ 
        error: authError.message || 'Failed to create user account' 
      }, { status: 500 })
    }

    if (!authData.user) {
      return NextResponse.json({ 
        error: 'Failed to create user account' 
      }, { status: 500 })
    }

    // Create or update profile for the new user
    const { data: newProfile, error: profileError } = await adminClient
      .from('profiles')
      .upsert({
        id: authData.user.id,
        email: email,
        full_name: full_name,
        phone: phone || null,
        role: 'technician',
        is_active: true
      })
      .select()
      .single()

    if (profileError) {
      console.error('Error creating technician profile:', profileError)
      // Note: Auth user was created, but profile failed
      // In production, you might want to delete the auth user here
      return NextResponse.json({ 
        error: 'User created but profile setup failed. Please contact support.' 
      }, { status: 500 })
    }

    return NextResponse.json({ 
      success: true,
      technician: newProfile,
      credentials: {
        email: email,
        temporaryPassword: password
      },
      message: 'Technician created successfully!'
    })

  } catch (error) {
    console.error('Error creating technician:', error)
    return NextResponse.json({ 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}
EOF

# Step 3: Create an API to update/deactivate technicians
mkdir -p app/api/technicians/update
cat > app/api/technicians/update/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { NextResponse } from 'next/server'

export async function PUT(request: Request) {
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

    const { technicianId, updates, resetPassword } = await request.json()

    if (!technicianId) {
      return NextResponse.json({ error: 'Technician ID required' }, { status: 400 })
    }

    const adminClient = createAdminClient()

    // Update profile
    const { data: updatedProfile, error: profileError } = await adminClient
      .from('profiles')
      .update({
        full_name: updates.full_name,
        phone: updates.phone,
        is_active: updates.is_active,
        updated_at: new Date().toISOString()
      })
      .eq('id', technicianId)
      .select()
      .single()

    if (profileError) {
      return NextResponse.json({ 
        error: 'Failed to update technician profile' 
      }, { status: 500 })
    }

    // Handle password reset if requested
    let newPassword = null
    if (resetPassword) {
      // Generate a random password
      newPassword = Math.random().toString(36).slice(-8) + 'A1!'
      
      const { error: passwordError } = await adminClient.auth.admin.updateUserById(
        technicianId,
        { password: newPassword }
      )

      if (passwordError) {
        console.error('Error resetting password:', passwordError)
        // Continue even if password reset fails
      }
    }

    // Handle deactivation - disable auth access
    if (updates.is_active === false) {
      // Ban the user from logging in
      const { error: banError } = await adminClient.auth.admin.updateUserById(
        technicianId,
        { ban_duration: '876000h' } // 100 years effectively permanent
      )

      if (banError) {
        console.error('Error deactivating user auth:', banError)
      }
    } else if (updates.is_active === true) {
      // Unban the user to allow login
      const { error: unbanError } = await adminClient.auth.admin.updateUserById(
        technicianId,
        { ban_duration: 'none' }
      )

      if (unbanError) {
        console.error('Error reactivating user auth:', unbanError)
      }
    }

    return NextResponse.json({ 
      success: true,
      technician: updatedProfile,
      ...(newPassword && { newPassword })
    })

  } catch (error) {
    console.error('Error updating technician:', error)
    return NextResponse.json({ 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}
EOF

# Step 4: Create API to list all auth users (for sync)
cat > app/api/technicians/sync/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { NextResponse } from 'next/server'

/**
 * Sync auth users with profiles table
 * Useful for ensuring all auth users have profiles
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

    // List all users
    const { data: { users }, error: listError } = await adminClient.auth.admin.listUsers()

    if (listError) {
      return NextResponse.json({ 
        error: 'Failed to list users' 
      }, { status: 500 })
    }

    // Sync each user with profiles
    const syncResults = []
    for (const authUser of users) {
      // Check if profile exists
      const { data: existingProfile } = await adminClient
        .from('profiles')
        .select('id')
        .eq('id', authUser.id)
        .single()

      if (!existingProfile) {
        // Create profile for auth user
        const { data: newProfile, error: createError } = await adminClient
          .from('profiles')
          .insert({
            id: authUser.id,
            email: authUser.email!,
            full_name: authUser.user_metadata?.full_name || authUser.email?.split('@')[0] || 'Unknown',
            role: authUser.user_metadata?.role || 'technician',
            is_active: !authUser.banned_until
          })
          .select()
          .single()

        syncResults.push({
          userId: authUser.id,
          email: authUser.email,
          action: 'created',
          success: !createError
        })
      } else {
        syncResults.push({
          userId: authUser.id,
          email: authUser.email,
          action: 'exists',
          success: true
        })
      }
    }

    return NextResponse.json({ 
      success: true,
      totalUsers: users.length,
      syncResults
    })

  } catch (error) {
    console.error('Error syncing users:', error)
    return NextResponse.json({ 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}
EOF

# Step 5: Update the AddTechnicianModal to show credentials
cat > app/\(authenticated\)/technicians/AddTechnicianModal.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card } from '@/components/ui/card'
import { X, Loader2, Check, Copy } from 'lucide-react'
import { toast } from 'sonner'

interface AddTechnicianModalProps {
  onClose: () => void
  onSuccess: () => void
}

export default function AddTechnicianModal({ onClose, onSuccess }: AddTechnicianModalProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [showCredentials, setShowCredentials] = useState(false)
  const [credentials, setCredentials] = useState<{email: string, password: string} | null>(null)
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    temporaryPassword: ''
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.fullName || !formData.email || !formData.temporaryPassword) {
      toast.error('Please fill in all required fields')
      return
    }

    if (formData.temporaryPassword.length < 6) {
      toast.error('Password must be at least 6 characters')
      return
    }

    setIsLoading(true)

    try {
      const response = await fetch('/api/technicians/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: formData.email,
          password: formData.temporaryPassword,
          full_name: formData.fullName,
          phone: formData.phone
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to create technician')
      }

      // Show credentials
      setCredentials({
        email: formData.email,
        password: formData.temporaryPassword
      })
      setShowCredentials(true)
      
      toast.success('Technician created successfully!')
      
      // Wait a bit then close
      setTimeout(() => {
        onSuccess()
      }, 3000)
      
    } catch (error: any) {
      toast.error(error.message || 'Failed to create technician')
      setIsLoading(false)
    }
  }

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text)
    toast.success(`${label} copied to clipboard`)
  }

  if (showCredentials && credentials) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg p-6 w-full max-w-md">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold">Technician Created!</h2>
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="space-y-4">
            <div className="flex items-center gap-2 text-green-600 mb-4">
              <Check className="h-5 w-5" />
              <span className="font-medium">Account created successfully</span>
            </div>

            <Card className="p-4 bg-blue-50 border-blue-200">
              <p className="text-sm font-medium mb-3">Share these credentials with the technician:</p>
              
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Email:</span>
                  <div className="flex items-center gap-2">
                    <code className="bg-white px-2 py-1 rounded text-sm">{credentials.email}</code>
                    <button
                      onClick={() => copyToClipboard(credentials.email, 'Email')}
                      className="text-blue-600 hover:text-blue-800"
                    >
                      <Copy className="h-4 w-4" />
                    </button>
                  </div>
                </div>
                
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Password:</span>
                  <div className="flex items-center gap-2">
                    <code className="bg-white px-2 py-1 rounded text-sm">{credentials.password}</code>
                    <button
                      onClick={() => copyToClipboard(credentials.password, 'Password')}
                      className="text-blue-600 hover:text-blue-800"
                    >
                      <Copy className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>

              <p className="text-xs text-gray-600 mt-3">
                The technician should change their password after first login.
              </p>
            </Card>

            <Button onClick={onClose} className="w-full">
              Done
            </Button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Add New Technician</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="fullName">Full Name *</Label>
            <Input
              id="fullName"
              type="text"
              value={formData.fullName}
              onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
              placeholder="John Smith"
              required
            />
          </div>

          <div>
            <Label htmlFor="email">Email Address *</Label>
            <Input
              id="email"
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              placeholder="john@example.com"
              required
            />
            <p className="text-xs text-muted-foreground mt-1">
              This will be their login email
            </p>
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

          <div>
            <Label htmlFor="password">Temporary Password *</Label>
            <Input
              id="password"
              type="text"
              value={formData.temporaryPassword}
              onChange={(e) => setFormData({ ...formData, temporaryPassword: e.target.value })}
              placeholder="Min 6 characters"
              required
              minLength={6}
            />
            <p className="text-xs text-muted-foreground mt-1">
              You'll be able to copy this after creation
            </p>
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
                  Creating...
                </>
              ) : (
                'Create Technician'
              )}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

# Commit everything
git add .
git commit -m "feat: implement full auth user creation with Supabase Admin API"
git push origin main

echo "✅ Full auth user creation setup complete!"
echo ""
echo "🔐 IMPORTANT NEXT STEPS:"
echo ""
echo "1. Add SUPABASE_SERVICE_ROLE_KEY to Vercel environment variables"
echo "   - Go to Vercel Dashboard → Settings → Environment Variables"
echo "   - Add the key from Supabase Dashboard → Settings → API → Service Role Key"
echo ""
echo "2. Redeploy your application for changes to take effect"
echo ""
echo "3. Test creating a technician:"
echo "   - Go to /technicians"
echo "   - Click 'Add Technician'"
echo "   - The new technician can immediately log in with their credentials"
echo ""
echo "⚠️ SECURITY NOTES:"
echo "- Service role key has FULL database access"
echo "- NEVER expose it in client-side code"
echo "- NEVER commit it to git"
echo "- Only use in server-side API routes"