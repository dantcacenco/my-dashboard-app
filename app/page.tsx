import { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import DashboardContent from './DashboardContent';

export const metadata: Metadata = {
  title: 'Dashboard | Service Pro',
  description: 'Service management dashboard',
};

export default async function DashboardPage() {
  const supabase = await createClient();

  // Check authentication
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    redirect('/auth/signin');
  }

  // Verify user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  if (!profile || !['admin', 'boss'].includes(profile.role)) {
    redirect('/unauthorized');
  }

  return <DashboardContent />;
}
