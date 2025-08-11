import { createServerComponentClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import JobDetailView from './JobDetailView';

export default async function JobPage({
  params
}: {
  params: Promise<{ id: string }>
}) {
  const supabase = createServerComponentClient({ cookies });
  
  // Await the params (Next.js 15 requirement)
  const { id } = await params;

  // Check authentication
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    redirect('/auth/signin');
  }

  // Check user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  // Only boss, admin, and technician can view jobs
  if (!profile || (profile.role !== 'boss' && profile.role !== 'admin' && profile.role !== 'technician')) {
    redirect('/');
  }

  // Pass only the jobId to JobDetailView
  // JobDetailView will fetch its own data
  return <JobDetailView jobId={id} />;
}
