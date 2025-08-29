# MASTER WORKING SESSION - Service Pro HVAC Management System
**Last Updated:** August 29, 2025  
**Version:** Active Development  
**Project Path:** `/Users/dantcacenco/Documents/GitHub/my-dashboard-app`
**Domain:** `https://fairairhc.service-pro.app`

## 🏗️ SYSTEM ARCHITECTURE UNDERSTANDING

### Core Technology Stack
- **Frontend:** Next.js 15.4.3 (App Router) + TypeScript
- **Database:** Supabase (PostgreSQL with RLS policies)
- **Auth:** Supabase Auth (multi-tenant with roles)
- **Payments:** Stripe (50/30/20 payment split model) + Manual payment recording
- **Future:** Bill.com integration for invoicing (client already uses)
- **Email:** Resend API (PRODUCTION READY - fairairhc.service-pro.app domain)
- **Storage:** Supabase Storage (job-photos, job-files, check-images buckets)
- **UI:** Tailwind CSS + shadcn/ui components
- **Hosting:** Vercel (automatic deployments from GitHub)

### Data Flow Architecture
```
Customer → Proposal → Job → Technician Assignment → Completion → Payment → Reminders
           ↓          ↓                                    ↓           ↓
        Email      Status Sync                     Auto Reminders   Admin Alerts
           ↓          ↓                                    ↓           ↓
        Token    DB Triggers                        Email Queue   Dashboard
```

## 🚨 IMMEDIATE ACTION REQUIRED

### Run SQL Migration for Payment Recording
**CRITICAL**: The Record Payment feature won't work until you run the SQL migration in Supabase!

1. **Go to Supabase SQL Editor**
2. **Copy the entire script from:** `database_migrations/create_check_images_bucket.sql`
3. **Run it** to create the storage bucket and improved payment triggers

This migration:
- Creates `check-images` storage bucket (fixes "Bucket not found" error)
- Adds improved payment tracking with overpayment handling
- Updates proposal status automatically based on payments
- Adds `total_paid` column if missing

See `RUN_THIS_SQL_MIGRATION.md` for detailed instructions.

## ✅ LATEST UPDATES (August 29, 2025 - Evening Session)

### Session Date: August 29, 2025 (Updated)

#### Previous Completions (v2.3)
- ✅ Email System Production Ready
- ✅ Manual Payment Recording infrastructure
- ✅ Domain & Environment Setup

#### Latest Updates (Evening Session)
1. **Payment Recording Fixes**
   - ✅ Fixed "Bucket not found" error with graceful fallback
   - ✅ Created SQL migration for check-images bucket
   - ✅ Improved error handling for storage operations
   - ✅ Component continues working even if image upload fails

2. **Comprehensive Payment Tracking**
   - ✅ Created PaymentBalance component showing:
     - Total paid vs remaining balance
     - Payment status per stage (deposit/progress/final)
     - Overpayment detection and alerts
     - Complete payment history
   - ✅ Improved payment trigger with smart status updates
   - ✅ Handles partial payments and overpayments

3. **Database Improvements**
   - ✅ Created improved payment trigger function
   - ✅ Automatic proposal status updates based on payments
   - ✅ Tracks total_paid amount on proposals
   - ✅ Smart payment stage completion detection

4. **UI Enhancements**
   - ✅ Record Payment modal properly integrated
   - ✅ PaymentBalance component shows detailed breakdown
   - ✅ Visual indicators for paid/due/overpaid stages
   - ✅ Payment history with method and notes

#### Earlier Today (Morning Session)
1. **Record Payment Modal Integration**
   - ✅ Added RecordManualPayment modal to ProposalView
   - ✅ Created missing Select UI component
   - ✅ Modal properly connected with success handlers
   - ✅ Toast notifications for payment recording

2. **Button Order Maintained**
   - ✅ Verified button order matches requirements
   - ✅ Back button left-aligned
   - ✅ Action buttons right-aligned in correct order
   - ✅ "Record Payment" button properly labeled

3. **Bill.com Integration Planning**
   - ✅ Created revised integration plan (BILLCOM_INVOICE_SYNC_PLAN.md)
   - ✅ Clarified Bill.com is for INVOICING ONLY, not payments
   - ✅ Simplified approach: one-way sync for invoice creation
   - ✅ Maintaining Stripe for actual payment processing

## 📋 NEXT CHAT REQUIREMENTS

### 1. Bill.com Invoice Sync Implementation
**Understanding:** Client uses Bill.com for invoice generation/tracking ONLY
- Not for payment processing (keep Stripe)
- One-way sync: Service Pro → Bill.com
- Create invoices automatically when proposals are approved

**Implementation Steps:**
1. Get Bill.com API credentials from client
2. Add "Send to Bill.com" button to approved proposals
3. Create simple API route for invoice creation
4. Track Bill.com invoice ID in proposals table
5. Show invoice number and sync status

**Reference:** See `BILLCOM_INVOICE_SYNC_PLAN.md` for detailed approach

### 2. Testing & Deployment
- Test manual payment recording in production
- Verify all modals work correctly
- Ensure build passes without errors
- Deploy to production

### 3. Future Enhancements to Consider
- Sunbit/Affirm financing options (as mentioned in docs)
- Bulk operations for proposals
- Enhanced reporting for manual payments
- Invoice status webhooks from Bill.com (later phase)

## 🔑 KEY ARCHITECTURAL INSIGHTS

### 1. Database Design Philosophy
- **Proposals** are source of truth for financial data
- **Jobs** are operational entities from proposals
- **Bidirectional sync** via PostgreSQL triggers
- **Payment tracking** in proposals (deposit_amount, progress_payment_amount, final_payment_amount)
- **Manual payments** table for cash/check recording

### 2. Email System Architecture
- **From:** `noreply@fairairhc.service-pro.app`
- **Reply-To:** `dantcacenco@gmail.com` (testing) → `fairairhc@gmail.com` (production)
- **Templates:** Professional HTML with consistent branding
- **Tracking:** Database table monitors usage, alerts at limits

### 3. Payment System Reality
- **Stripe:** For online credit card and ACH payments
- **Manual Recording:** For cash/check payments with image upload
- **Bill.com:** For invoice generation ONLY (not payment processing)
- **Payment Tracking:** 
  - Automatic status updates via database triggers
  - Handles overpayments with alerts
  - Tracks payment history by stage
  - Shows remaining balance per stage
- **Future:** Consider Sunbit/Affirm for financing options

### 4. User Role Architecture
```typescript
type UserRole = 'boss' | 'technician' // Check for both 'boss' and 'admin'
// Boss sees: Full system, financials, all jobs
// Technician sees: Assigned jobs only, no financials, time tracking
```

## 💡 CRITICAL PATTERNS & RULES

### 1. Supabase Join Pattern
```typescript
// ✅ CORRECT - Supabase returns OBJECT not ARRAY
const customer = job.customers    // Direct object access
// ❌ WRONG
const customer = job.customers[0] // This will fail
```

### 2. Environment Variables
- `.env.local` does NOT sync with Vercel
- Must manually update both places
- Vercel changes require redeployment to take effect

### 3. File Storage Pattern
```javascript
// Storage buckets use hyphens, not underscores
const buckets = {
  photos: 'job-photos',       // NOT job_photos
  files: 'job-files',         // NOT job_files  
  checks: 'check-images'       // For manual payment proofs
}
```

### 4. Email Best Practices
- Always use environment variables for URLs
- Include company name consistently
- Test with real domains before production
- Monitor usage to avoid limits

## ⚠️ NEVER MODIFY WITHOUT TESTING
1. **Payment routing** (working perfectly)
2. **Customer proposal view UI** (client loves current design)
3. **Database triggers** (complex bidirectional sync)
4. **Status sync functions** (core business logic)
5. **Webhook processing** (payment critical)

## 🚀 DEPLOYMENT & TESTING

### Build & Deploy
```bash
# Local build test
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build

# Deploy (automatic via Vercel on push)
git add -A && git commit -m "Description" && git push origin main

# Tag stable releases
git tag -a v2.3-stable -m "Release description"
git push origin v2.3-stable
```

### Testing Checklist
1. **Email System:** Send test proposal, verify template
2. **Manual Payments:** Record cash/check, verify status update
3. **Domain:** All links use fairairhc.service-pro.app
4. **Button Order:** Verify new proposal view layout
5. **Build:** No TypeScript errors before deploy

## 🎯 IMMEDIATE NEXT STEPS

### For Next Chat Session:
1. **Reorder proposal view buttons** as specified
2. **Add "Record Payment" button** to proposal view
3. **Research Bill.com invoice sync** (not payment processing)
4. **Maintain all existing functionality**

### Implementation Notes:
- Bill.com is for INVOICING, not payment collection
- Keep Stripe for payments
- Manual payment recording for cash/checks
- Think about invoice number sync between systems

## 📝 DEVELOPMENT PHILOSOPHY
1. **Minimal Changes:** Don't fix what isn't broken
2. **Test First:** Always run build before pushing
3. **Preserve UI:** Don't change design unless explicitly asked
4. **Use Existing Patterns:** Follow established code patterns
5. **Document Intentions:** Clear commit messages
6. **Clean Project:** Delete temp files after use
7. **Client First:** Understand their actual workflow before coding

## 🔐 CREDENTIALS & ENVIRONMENT
```bash
# Database
Project Ref: dqcxwekmehrqkigcufug
URL: https://dqcxwekmehrqkigcufug.supabase.co
Direct SQL: postgresql://postgres.dqcxwekmehrqkigcufug:zEnhom-qaxfir-2xypmi@aws-0-us-east-1.pooler.supabase.com:6543/postgres

# Production Domain
URL: https://fairairhc.service-pro.app

# Required .env.local variables
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
RESEND_API_KEY  # Production ready
EMAIL_FROM=noreply@fairairhc.service-pro.app
REPLY_TO_EMAIL=dantcacenco@gmail.com
BUSINESS_EMAIL=dantcacenco@gmail.com
NEXT_PUBLIC_BASE_URL=https://fairairhc.service-pro.app
STRIPE_SECRET_KEY
STRIPE_PUBLISHABLE_KEY
STRIPE_WEBHOOK_SECRET
DATABASE_URL
```

## 🎓 KEY LESSONS FROM THIS SESSION

### What We Learned:
1. **Bill.com Reality:** It's B2B only, not for consumer payments
2. **Client Uses Bill.com:** For invoicing, not payment processing
3. **Manual Payments:** Simple button beats complex OCR scanning
4. **Email Domains:** Must be verified in Resend for production
5. **Environment Sync:** Vercel and local .env don't auto-sync

### Best Practices Confirmed:
1. **Keep It Simple:** Manual payment recording > Check scanning
2. **Understand First:** Client workflow before implementation
3. **Test Domains:** Always verify before sending to customers
4. **Stable Releases:** Tag working versions for rollback
5. **Clear Communication:** Separate invoicing from payment processing

## 📂 PROJECT STRUCTURE (Updated)

```
app/
├── (authenticated)/         # Protected routes
│   ├── proposals/          # Proposal system (needs button reorder)
│   │   └── [id]/          # Detail view (add Record Payment)
│   ├── jobs/              # Job management
│   └── technician/        # Technician portal
├── proposal/              # Public customer view
└── api/                   # API routes
    ├── stripe/            # Payment processing (keep)
    ├── billcom/           # Invoice sync (to implement)
    └── manual-payment/    # Cash/check recording (to add)

components/
├── RecordManualPayment.tsx # Ready to integrate
├── EmailUsageWidget.tsx    # Email monitoring
└── email-templates.ts      # Professional templates

lib/
├── email-tracking.ts      # Usage monitoring
├── billcom/              # To implement for invoicing
└── stripe/               # Payment processing

database_migrations/
├── create_manual_payments_table.sql  # Completed
└── create_billcom_sync_table.sql    # To create
```

---
**This document represents the current state and next requirements for Service Pro HVAC System as of Version 2.4 STABLE. 

## Summary of Today's Session:
1. ✅ Successfully integrated RecordManualPayment modal into ProposalView
2. ✅ Created missing Select UI component for payment recording
3. ✅ Verified button order matches requirements
4. ✅ Created revised Bill.com integration plan focusing on invoice sync only
5. ✅ Clarified that Bill.com is for invoicing, NOT payment processing

Next session should focus on implementing the Bill.com invoice sync feature after obtaining API credentials from the client.**