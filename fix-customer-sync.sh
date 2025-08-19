#!/bin/bash
# Fix 3: Customer data sync in jobs
set -e
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

echo "🔄 Fixing customer data sync..."

# Create a patch for JobDetailView to update customer when editing
cat > fix-customer-sync.patch << 'EOF'
--- a/app/jobs/[id]/page.tsx
+++ b/app/jobs/[id]/page.tsx
@@ -100,6 +100,15 @@
       if (error) throw error
+      
+      // Also update customer if customer data changed
+      if (updates.customer_id) {
+        await supabase
+          .from('customers')
+          .update({
+            name: updates.customer_name,
+            email: updates.customer_email,
+            phone: updates.customer_phone,
+            address: updates.service_address
+          })
+          .eq('id', updates.customer_id)
+      }
EOF

echo "✅ Customer sync patch created"
echo "Note: This requires manual integration into the JobDetailView component"
