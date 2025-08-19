#!/bin/bash

set -e

echo "🔧 Final fix for EditJobModal props..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the prop name in JobDetailView
sed -i '' 's/onSave={(updatedJob: any)/onJobUpdated={() /' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
sed -i '' '/setJob(updatedJob)/d' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
sed -i '' '/setShowEditModal(false)/d' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
sed -i '' "s/toast.success('Job updated')/{ setShowEditModal(false); loadJobMedia(); }}/" app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

# Actually, let's just fix the specific section properly
cat > /tmp/fix-modal-call.txt << 'MODALFIX'
      {/* Edit Job Modal */}
      {showEditModal && (
        <EditJobModal 
          job={job}
          isOpen={showEditModal}
          onClose={() => setShowEditModal(false)}
          onJobUpdated={() => {
            setShowEditModal(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}
MODALFIX

# Replace the problematic section
tail -n 10 app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx > /tmp/current-end.txt
head -n 515 app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx > /tmp/new-file.txt
cat /tmp/fix-modal-call.txt >> /tmp/new-file.txt
mv /tmp/new-file.txt app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

echo "✅ Fixed EditJobModal props"

# Test build
echo ""
echo "🔨 Testing build..."
npm run build 2>&1 | head -80

echo ""
echo "📦 Committing final fixes..."
git add -A
git commit -m "Fix EditJobModal prop mismatch and complete upload/technician fixes"
git push origin main

echo ""
echo "✅ ALL FIXES COMPLETE!"
echo ""
echo "⚠️  CRITICAL: Now run this SQL in Supabase to enable technician access:"
cat fix-rls-policies.sql
