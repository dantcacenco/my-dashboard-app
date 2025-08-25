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

    if (profile?.role !== 'admin' && profile?.role !== 'admin') {
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
