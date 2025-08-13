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
