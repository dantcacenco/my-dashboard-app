# URGENT: Run This SQL Migration in Supabase

## The Issue
The "Record Payment" feature is failing because the `check-images` storage bucket doesn't exist in Supabase.

## Solution
Run the SQL script below in your Supabase SQL Editor to:
1. Create the `check-images` storage bucket
2. Set up proper RLS policies for the bucket
3. Add improved payment tracking with overpayment handling
4. Fix the payment status updates

## Steps to Apply:

1. Go to your Supabase Dashboard
2. Navigate to SQL Editor (in the left sidebar)
3. Copy and paste the entire SQL script from `database_migrations/create_check_images_bucket.sql`
4. Click "Run" to execute

## What This Migration Does:

### 1. Creates Storage Bucket
- Creates `check-images` bucket for storing check photos
- Sets 5MB file size limit
- Only allows image uploads (jpeg, png, etc.)

### 2. Improves Payment Tracking
- Adds `total_paid` column to proposals (if missing)
- Creates smarter trigger that:
  - Tracks payments by stage
  - Handles overpayments properly
  - Updates proposal status automatically
  - Sets payment timestamps when stages are fully paid

### 3. Payment Logic Improvements
The new trigger handles these scenarios:
- **Normal payments**: Updates the correct stage and marks as paid when complete
- **Overpayments**: If customer pays $5 extra on deposit, it tracks but doesn't auto-apply to next stage (manual review needed)
- **Partial payments**: Tracks what's been paid vs what's due for each stage
- **Status updates**: Automatically updates proposal status as payments come in

## After Running the Migration:

1. Test recording a manual payment - it should work without the "Bucket not found" error
2. The payment will automatically update the proposal status
3. You'll see a detailed payment summary showing:
   - Total paid vs remaining
   - Each stage's payment status
   - Any overpayments that need attention
   - Complete payment history

## Payment Flow Example:

**Scenario**: $9,000 total job
- Deposit (50%): $4,500 due
- Progress (30%): $2,700 due  
- Final (20%): $1,800 due

**If customer pays $4,505 for deposit**:
- Deposit stage: Marked as PAID ✓
- Shows $5 overpayment alert
- Admin can decide to apply to next stage or refund

## Current Implementation Status:

✅ RecordManualPayment component ready
✅ PaymentBalance component shows detailed payment tracking
✅ Error handling for missing bucket
✅ SQL migration ready to run

⚠️ **ACTION REQUIRED**: Run the SQL migration in Supabase before testing!

## Files to Review:
- `/database_migrations/create_check_images_bucket.sql` - The migration to run
- `/components/PaymentBalance.tsx` - New payment tracking UI
- `/components/RecordManualPayment.tsx` - Updated with better error handling