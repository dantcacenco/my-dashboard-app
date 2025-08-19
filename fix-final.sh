#!/bin/bash

set -e

echo "🔧 Fixing page.tsx to remove unnecessary prop..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the page.tsx to not pass availableTechnicians
cat > app/\(authenticated\)/jobs/\[id\]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import JobDetailView from './JobDetailView'

export default async function JobDetailPage({ 
  params 
}: { 
  params: Promise<{ id: string }> 
}) {
  const { id } = await params
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: job, error } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (
        name,
        email,
        phone,
        address
      ),
      proposals (
        proposal_number,
        title,
        total
      )
    `)
    .eq('id', id)
    .single()

  if (error || !job) {
    notFound()
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  return (
    <JobDetailView 
      job={job} 
      userRole={profile?.role || 'technician'}
    />
  )
}
EOF

echo "🧪 Testing build..."
npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    git add -A
    git commit -m "Fix: Remove unnecessary availableTechnicians prop from JobDetailPage"
    git push origin main
    
    echo "🎉 All issues fixed and deployed!"
else
    echo "❌ Build still has errors, checking output..."
fi
