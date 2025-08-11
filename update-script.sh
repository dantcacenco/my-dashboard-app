#!/bin/bash
echo "🔧 Fixing proposals page access for boss role..."

# Fix the proposals page to accept both admin and boss roles
echo "📝 Updating proposals page role check..."
cat > app/proposals/page.tsx << 'EOF'
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
  if (!profile || (profile.role !== 'admin' && profile.role !== 'boss')) {
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
EOF

# Also update the proposals/[id]/page.tsx to ensure consistency
echo "📝 Updating proposal detail page role check..."
cat > app/proposals/[id]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalView from './ProposalView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()

  // Get current user
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  
  if (authError || !user) {
    redirect('/auth/login')
  }

  // Get user profile
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profileError || !profile) {
    redirect('/')
  }

  // Check authorization - allow both admin and boss
  if (profile.role !== 'admin' && profile.role !== 'boss') {
    redirect('/')
  }

  // Get proposal with all related data
  const { data: proposal, error } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone,
        address
      ),
      proposal_items (
        id,
        name,
        description,
        quantity,
        unit_price,
        total_price,
        is_addon,
        is_selected,
        sort_order
      )
    `)
    .eq('id', id)
    .single()

  if (error || !proposal) {
    console.error('Error fetching proposal:', error)
    redirect('/proposals')
  }

  return (
    <ProposalView 
      proposal={proposal} 
      userRole={profile.role}
    />
  )
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error writing files"
    exit 1
fi

# Commit and push
git add .
git commit -m "fix: allow boss role to access proposals pages

- Updated proposals page to accept both admin and boss roles
- Updated proposal detail page for consistency
- Fixed role checks to prevent redirect loops"
git push origin main

echo "✅ Proposals page access fixed!"
echo ""
echo "📝 The proposals page should now be accessible for users with 'boss' role"
echo ""
echo "🔧 Test by clicking on 'Proposals' in the navigation - it should work now!"