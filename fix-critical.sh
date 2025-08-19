#!/bin/bash
# Fix critical proposal and customer sync issues

set -e
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

echo "🚨 Fixing critical issues..."

# Check if proposal_activities table exists, if not create it
cat > check-tables.sql << 'EOF'
-- Check and create missing tables
CREATE TABLE IF NOT EXISTS proposal_activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  proposal_id UUID REFERENCES proposals(id) ON DELETE CASCADE,
  activity TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns if they don't exist
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS job_id UUID REFERENCES jobs(id);
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS job_created BOOLEAN DEFAULT false;

-- Create job_proposals junction table if missing
CREATE TABLE IF NOT EXISTS job_proposals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  proposal_id UUID REFERENCES proposals(id) ON DELETE CASCADE,
  attached_at TIMESTAMPTZ DEFAULT NOW(),
  attached_by UUID REFERENCES profiles(id),
  UNIQUE(job_id, proposal_id)
);

-- Ensure job columns exist
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_email TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS total_value NUMERIC DEFAULT 0;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);
EOF

echo "✅ SQL script created: check-tables.sql"
echo ""
echo "⚠️ IMPORTANT: Run this SQL in your Supabase dashboard:"
echo "1. Go to https://supabase.com/dashboard/project/_/sql/new"
echo "2. Paste the contents of check-tables.sql"
echo "3. Click 'Run'"
echo ""

# Update working session
echo "📝 Updating working session..."
cat >> working-session-august-19.md << 'EOF'

## 🔧 Latest Fixes Applied

### Fixed Components:
- ✅ Photo upload with multiple file selection
- ✅ File upload with multiple file selection  
- ✅ TechnicianSearch component created
- ✅ Removed Invoices from navigation

### Database Requirements:
Run the SQL in `check-tables.sql` to ensure all required tables/columns exist:
- proposal_activities table
- job_proposals junction table
- Missing columns in proposals and jobs tables

### Known Issues Remaining:
1. **Proposal Approval**: Need to verify database tables exist
2. **Customer Data Sync**: Patch created in fix-customer-sync.sh
3. **Mobile View**: Buttons may overflow container
4. **Proposal Statuses**: Need expanded status options
5. **Add-ons vs Services**: Need checkbox implementation

EOF

echo "✅ Working session updated"
echo ""
echo "📋 Next Steps:"
echo "1. Run the SQL script in Supabase"
echo "2. Test proposal approval flow"
echo "3. Test file/photo uploads"
echo "4. Verify technician dropdown works"
echo ""
echo "Run 'npm run dev' to test locally"
