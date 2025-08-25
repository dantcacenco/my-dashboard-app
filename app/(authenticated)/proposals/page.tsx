import { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import ProposalsList from './ProposalsList';

export const metadata: Metadata = {
  title: 'Proposals | Service Pro',
  description: 'Manage your service proposals',
};

export default async function ProposalsPage() {
  const supabase = await createClient();

  // Check authentication
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    redirect('/auth/login');
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  // Allow both admin and boss roles
  if (!profile || (profile.role !== 'boss' && profile.role !== 'boss')) {
    redirect('/');
  }

  // Fetch proposals with customer data
  const { data: proposals, error } = await supabase
    .from('proposals')
    .select(`
      *,
      customers!inner (
        id,
        name,
        email,
        phone
      )
    `)
    .order('updated_at', { ascending: false });

  if (error) {
    console.error('Error fetching proposals:', error);
  }

  return <ProposalsList initialProposals={proposals || []} />;
}
