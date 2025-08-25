import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import NewJobForm from './NewJobForm'

export default async function NewJobPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  // Get user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()
  
  // Only boss/admin can create jobs
  if (profile?.role !== 'boss') {
    redirect('/jobs')
  }

  // Fetch customers and proposals
  const [customersRes, proposalsRes] = await Promise.all([
    supabase
      .from('customers')
      .select('id, name, email, phone, address')
      .order('name'),
    
    supabase
      .from('proposals')
      .select(`
        id, 
        proposal_number, 
        title, 
        status, 
        customer_id,
        total,
        customers (
          name,
          address
        ),
        proposal_items (
          name,
          description,
          quantity,
          is_addon,
          is_selected
        )
      `)
      .eq('status', 'approved')
      .order('created_at', { ascending: false })
  ])

  // Try multiple approaches to get technicians
  console.log('Attempting to fetch technicians...')
  
  // Approach 1: Standard query
  const { data: technicians1, error: error1 } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, is_active')
    .eq('role', 'technician')
    .eq('is_active', true)
  
  console.log('Approach 1 - role=technician, is_active=true:', {
    count: technicians1?.length,
    error: error1?.message,
    data: technicians1
  })

  // Approach 2: Just role = technician
  const { data: technicians2, error: error2 } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, is_active')
    .eq('role', 'technician')
  
  console.log('Approach 2 - just role=technician:', {
    count: technicians2?.length,
    error: error2?.message,
    data: technicians2
  })

  // Approach 3: All profiles to see what roles exist
  const { data: allProfiles, error: error3 } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, is_active')
  
  const roleCount = allProfiles?.reduce((acc, p) => {
    acc[p.role] = (acc[p.role] || 0) + 1
    return acc
  }, {} as Record<string, number>)
  
  console.log('Approach 3 - all profiles by role:', {
    totalProfiles: allProfiles?.length,
    roleBreakdown: roleCount,
    error: error3?.message
  })

  // Use the best result
  const technicians = technicians1 || technicians2 || []
  
  // If still no technicians, try to get any active user that's not boss/admin
  let finalTechnicians = technicians
  if (technicians.length === 0 && allProfiles) {
    finalTechnicians = allProfiles.filter(p => 
      p.role !== 'boss' && 
      p.role !== 'boss' && 
      (p.is_active === true || p.is_active === null)
    )
    console.log('Using fallback technicians (non-boss/admin):', finalTechnicians)
  }

  console.log('Final technicians being passed to form:', {
    count: finalTechnicians.length,
    technicians: finalTechnicians
  })

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-2xl font-bold mb-6">Create New Job</h1>
        <NewJobForm 
          customers={customersRes.data || []}
          proposals={proposalsRes.data || []}
          technicians={finalTechnicians}
          userId={user.id}
        />
        
        {/* Debug info in development */}
        {process.env.NODE_ENV === 'development' && (
          <div className="mt-8 p-4 bg-gray-100 rounded text-xs">
            <h3 className="font-bold mb-2">Debug Info (Dev Only)</h3>
            <p>Technicians found: {finalTechnicians.length}</p>
            <p>Profile roles in DB: {JSON.stringify(roleCount)}</p>
            <button
              onClick={() => window.location.href = '/api/debug-technicians'}
              className="mt-2 px-3 py-1 bg-blue-500 text-white rounded text-xs"
            >
              Check Technician Debug API
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
