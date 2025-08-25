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

    if (profile?.role !== 'admin' && profile?.role !== 'admin') {
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
