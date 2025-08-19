import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET() {
  try {
    const supabase = await createClient()
    
    // Check auth
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Get ALL profiles to see what's in there
    const { data: allProfiles, error: allError } = await supabase
      .from('profiles')
      .select('*')

    // Get profiles with role = technician
    const { data: techProfiles, error: techError } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')

    // Get active technicians
    const { data: activeTechs, error: activeError } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
      .eq('is_active', true)

    return NextResponse.json({
      debug: {
        totalProfiles: allProfiles?.length || 0,
        allProfiles: allProfiles,
        techniciansWithRole: techProfiles?.length || 0,
        techProfiles: techProfiles,
        activeTechnicians: activeTechs?.length || 0,
        activeTechs: activeTechs,
        errors: {
          all: allError?.message,
          tech: techError?.message,
          active: activeError?.message
        }
      }
    })
  } catch (error) {
    return NextResponse.json({ error: 'Server error', details: error }, { status: 500 })
  }
}
