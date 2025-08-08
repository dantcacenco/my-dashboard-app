export interface User {
  id: string;
  email: string;
  role: 'admin' | 'boss' | 'technician';
}

export interface Customer {
  id: string;
  name: string;
  email: string;
  phone?: string;
  address?: string;
  created_at: string;
  updated_at: string;
  user_id: string;
}

export interface LineItem {
  id?: string;
  description: string;
  quantity: number;
  rate: number;
  amount: number;
}

export interface Proposal {
  id: string;
  proposal_number: string;
  customer_id: string;
  line_items: LineItem[];
  subtotal: number;
  tax_rate: number;
  tax_amount: number;
  total: number;
  status: 'draft' | 'sent' | 'approved' | 'rejected' | null;
  valid_until: string;
  notes?: string;
  terms?: string;
  created_at: string;
  updated_at: string;
  sent_at?: string | null;
  approved_at?: string | null;
  rejected_at?: string | null;
  rejection_reason?: string | null;
  customer_view_token?: string | null;
  deposit_percentage?: number;
  progress_percentage?: number;
  final_percentage?: number;
  deposit_amount?: number;
  progress_payment_amount?: number;
  final_payment_amount?: number;
  deposit_paid_at?: string | null;
  progress_paid_at?: string | null;
  final_paid_at?: string | null;
  payment_method?: string | null;
  payment_status?: string | null;
  stripe_session_id?: string | null;
  total_paid?: number;
  payment_stage?: string | null;
  current_payment_stage?: string | null;
  next_payment_due?: string | null;
  customer?: Customer;
  job_created?: boolean;
}

export interface Job {
  id: string;
  job_number: string;
  customer_id: string;
  proposal_id?: string;
  job_type: 'installation' | 'repair' | 'maintenance' | 'emergency';
  status: 'scheduled' | 'in_progress' | 'needs_attention' | 'completed' | 'cancelled';
  scheduled_date?: string;
  completed_date?: string;
  assigned_technician_id?: string;
  description?: string;
  notes?: string;
  service_address?: string;
  service_city?: string;
  service_state?: string;
  service_zip?: string;
  created_at: string;
  updated_at: string;
  created_by: string;
  customer?: Customer;
  proposal?: Proposal;
  technician?: {
    id: string;
    full_name: string;
  };
}

export interface JobWithRelations extends Job {
  customers?: Customer;
  proposals?: Proposal;
  profiles?: {
    id: string;
    full_name: string;
  };
}

export interface PaymentIntent {
  proposalId: string;
  amount: number;
  stage: 'deposit' | 'roughin' | 'final';
}
