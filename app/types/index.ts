// Comprehensive type definitions for the entire application

// Database table types (matching Supabase schema)
export interface Customer {
  id: string
  name: string
  email: string | null
  phone: string | null
  address: string | null
  notes: string | null
  created_by: string
  created_at: string
  updated_at: string
}

export interface Profile {
  id: string
  email: string
  full_name: string | null
  role: 'admin' | 'admin' | 'technician'
  phone: string | null
  created_at: string
  updated_at: string
}

export interface Proposal {
  id: string
  proposal_number: string
  customer_id: string
  title: string
  description: string | null
  subtotal: number
  tax_rate: number
  tax_amount: number
  total: number
  status: 'draft' | 'sent' | 'approved' | 'rejected' | 'paid'
  valid_until: string | null
  signed_at: string | null
  signature_data: string | null
  created_by: string
  created_at: string
  updated_at: string
  customer_view_token: string | null
  sent_at: string | null
  first_viewed_at: string | null
  approved_at: string | null
  rejected_at: string | null
  customer_notes: string | null
  payment_status: string | null
  payment_method: string | null
  stripe_session_id: string | null
  deposit_paid_at: string | null
  deposit_amount: number | null
  payment_initiated_at: string | null
  last_payment_attempt: string | null
  stripe_payment_intent_id: string | null
  progress_payment_amount: number | null
  progress_paid_at: string | null
  final_payment_amount: number | null
  final_paid_at: string | null
  total_paid: number
  payment_stage: string | null
  current_payment_stage: 'deposit' | 'roughin' | 'final' | null
  next_payment_due: number
  deposit_percentage: number
  progress_percentage: number
  final_percentage: number
  progress_amount: number
  final_amount: number
  job_created?: boolean
}

export interface Job {
  id: string
  job_number: string
  customer_id: string
  proposal_id: string | null
  title: string
  description: string | null
  job_type: 'installation' | 'repair' | 'maintenance' | 'emergency'
  status: 'scheduled' | 'started' | 'in_progress' | 'rough_in' | 'final' | 'complete'
  scheduled_date: string | null
  scheduled_time: string | null
  assigned_technician_id: string | null
  technician_id: string | null
  estimated_duration: string | null
  actual_start_time: string | null
  actual_end_time: string | null
  notes: string | null
  created_by: string
  created_at: string
  updated_at: string
  service_address: string | null
  service_city: string | null
  service_state: string | null
  service_zip: string | null
  boss_notes: string | null
  completion_notes: string | null
}

export interface ProposalItem {
  id: string
  proposal_id: string
  pricing_item_id: string | null
  name: string
  description: string | null
  quantity: number
  unit_price: number
  total_price: number
  is_addon: boolean
  is_selected: boolean
  sort_order: number
  created_at: string
}

// Joined types (for queries with relations)
export interface ProposalWithCustomer extends Proposal {
  customers: Customer
}

export interface ProposalWithItems extends Proposal {
  proposal_items: ProposalItem[]
}

export interface ProposalFull extends Proposal {
  customers: Customer
  proposal_items: ProposalItem[]
}

export interface JobWithRelations extends Job {
  customers: Customer
  proposals?: Proposal
  assigned_technician?: Profile
}
