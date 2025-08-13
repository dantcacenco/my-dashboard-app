import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

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

    // Create auth user with Supabase Admin API
    // Note: This requires service_role key for production
    // For now, we'll create just the profile
    
    // First check if user already exists
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id')
      .eq('email', email)
      .single()

    if (existingProfile) {
      return NextResponse.json({ 
        error: 'A user with this email already exists' 
      }, { status: 400 })
    }

    // Create a temporary user ID (in production, this would come from Auth)
    const tempUserId = crypto.randomUUID()

    // Create profile for technician
    const { data: newProfile, error: profileError } = await supabase
      .from('profiles')
      .insert({
        id: tempUserId,
        email: email,
        full_name: full_name,
        phone: phone,
        role: 'technician',
        is_active: true
      })
      .select()
      .single()

    if (profileError) {
      console.error('Error creating technician profile:', profileError)
      return NextResponse.json({ 
        error: 'Failed to create technician profile' 
      }, { status: 500 })
    }

    // Note: In production, you would also:
    // 1. Create the user in Supabase Auth using Admin API
    // 2. Send welcome email with login instructions
    // 3. Force password reset on first login

    return NextResponse.json({ 
      success: true,
      technician: newProfile,
      message: 'Technician created successfully. Note: Auth user creation requires additional setup.'
    })

  } catch (error) {
    console.error('Error creating technician:', error)
    return NextResponse.json({ 
      error: 'Internal server error' 
    }, { status: 500 })
  }
}
