import { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import JobDetailView from './JobDetailView';

export const metadata: Metadata = {
  title: 'Job Details | Service Pro',
  description: 'View and manage job details',
};

export default async function JobDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
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

  if (!profile || !['admin', 'boss', 'technician'].includes(profile.role)) {
    redirect('/unauthorized');
  }

  return <JobDetailView jobId={id} />;
}
