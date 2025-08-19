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
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/jobs')
  }

  // Fetch ALL data with proper joins
  const [customersRes, proposalsRes, techniciansRes] = await Promise.all([
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
      .order('created_at', { ascending: false }),
    
    supabase
      .from('profiles')
      .select('id, email, full_name, role, is_active')
      .eq('role', 'technician')
      .eq('is_active', true)
      .order('full_name')
  ])

  console.log('Server: Fetched data:', {
    customers: customersRes.data?.length,
    proposals: proposalsRes.data?.length,
    technicians: techniciansRes.data?.length,
    technicianDetails: techniciansRes.data
  })

  // Debug log if no technicians
  if (!techniciansRes.data || techniciansRes.data.length === 0) {
    console.error('No technicians found. Check profiles table for role=technician and is_active=true')
  }

  return (
    <div className="container mx-auto py-6 px-4">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-2xl font-bold mb-6">Create New Job</h1>
        <NewJobForm 
          customers={customersRes.data || []}
          proposals={proposalsRes.data || []}
          technicians={techniciansRes.data || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
