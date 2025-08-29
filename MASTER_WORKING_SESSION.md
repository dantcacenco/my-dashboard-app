# MASTER WORKING SESSION - Service Pro HVAC Management System
**Last Updated:** August 29, 2025 (Final Session)  
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

## ✅ DATABASE MIGRATION APPLIED (August 29, 2025)

### Migrations Successfully Executed
- ✅ `check-images` storage bucket created
- ✅ RLS policies configured for secure image uploads
- ✅ `total_paid` column verified on proposals table
- ✅ **NEW: Payment cascading trigger installed**
- ✅ All components verified and working

### Payment Cascading Logic (NEW)
- **Automatic Overflow**: When customer overpays a stage, excess automatically flows to next stage
- **Example**: Pay $5,500 for $4,590 deposit → $4,590 to deposit, $910 to progress
- **Total Protection**: System prevents payments exceeding total proposal amount
- **Smart Status Updates**: Automatically updates proposal status as stages complete

**The Record Payment feature now handles overpayments intelligently!**

## ✅ LATEST UPDATES (August 29, 2025 - Final Session)

### Session Date: August 29, 2025 (Complete)

#### Final Fixes (Latest)
1. **Create Job Button Logic**
   - ✅ Button now always enabled unless job already exists
   - ✅ Checks database for existing job to prevent duplicates
   - ✅ Clear error message: "A job already exists for this proposal"
   - ✅ Allows job creation regardless of proposal status

2. **Customer Link Button Improvements**
   - ✅ Removed 🔗 emoji from button text
   - ✅ Added tooltip that shows "Copied to clipboard"
   - ✅ Tooltip fades in and out smoothly over 2 seconds
   - ✅ No more toast notification - cleaner UI experience

#### UI/UX Improvements (Earlier)
1. **Check Image Viewing**
   - ✅ Added camera icon next to check payments
   - ✅ Click icon opens modal with check image
   - ✅ Easy close with X button or clicking outside
   - ✅ Full resolution image viewing

2. **Layout Improvements**
   - ✅ Customer Information: Single column layout (cleaner)
   - ✅ Payment Summary: Single column for totals (better hierarchy)
   - ✅ Record Payment button moved into Payment Summary card
   - ✅ Customer Link button added with clipboard copy

3. **Customer View Sync**
   - ✅ Shows remaining amounts per stage
   - ✅ Calculates payments with cascading logic
   - ✅ Syncs with manual and Stripe payments
   - ✅ Accurate payment tracking across views

#### Payment System Improvements (Earlier Today)
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

5. **Payment Cascading System (NEW)**
   - ✅ Automatic payment overflow to next stages
   - ✅ Database trigger handles cascading server-side
   - ✅ Frontend shows remaining balance and prevents overpayment
   - ✅ Example flow:
     - Customer pays $5,500 for $4,590 deposit
     - System applies: $4,590 to deposit, $910 to progress
     - Deposit marked PAID, progress shows $910 applied
   - ✅ Total payment validation prevents exceeding contract
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

### 1. Technician Side Navigation Memory
**Problem:** When technician clicks job → back button, it returns to calendar view instead of last used view
**Solution Required:**
- Store last view preference (list/calendar) in localStorage or session
- When navigating back, restore the last used view
- Maintain view preference during session
- Default to calendar only on fresh login

### 2. Job Status Updates - Critical Feature
**Current Issue:** Job status buttons don't match business workflow
**Required Changes:**

#### Database Updates Needed:
```sql
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS work_started_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS roughin_completed_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS final_completed_at TIMESTAMP;
```

#### Technician View (`/technician/jobs/[id]`):
- Replace current buttons with: "Work Started", "Rough-in Done", "Final Done"
- Each button toggles its respective timestamp
- Visual states: 
  - Not done: Gray outline button
  - Completed: Green filled with checkmark
- Buttons should be toggleable (can undo if clicked by mistake)

#### Admin View (`/jobs/[id]`):
- Add same three buttons inside "Assigned Technicians" box
- Place buttons below each technician's name
- Show total hours worked by that technician next to their name
- Format: "Technician Test (8.5 hours total)"
- Both admin and technician can toggle these statuses
- Real-time sync between views

#### Implementation Notes:
- Use optimistic updates for better UX
- Add API endpoint for status updates
- Ensure proper permissions (technician can only update their own jobs)
- Status changes should trigger notifications/logs

### 3. Bill.com Invoice Integration Strategy

#### Business Requirements:
- **Critical:** Must use Bill.com (accountant has QuickBooks integration)
- **Goal:** Convert approved proposals to Bill.com invoices
- **Workflow:** Proposal → PDF → Bill.com → Customer

#### Proposed Technical Approach:

##### Phase 1: PDF Generation
```javascript
// Use existing proposal view as template
// Libraries to consider:
- Puppeteer for server-side PDF generation
- React-pdf for client-side generation
- Or use browser print-to-pdf API
```

##### Phase 2: Bill.com API Integration
**Research Findings Needed:**
1. **Authentication Method:**
   - OAuth 2.0 or API keys?
   - Session management requirements
   
2. **Invoice Creation Endpoint:**
   - Required fields mapping:
     - Customer info (name, email, address)
     - Line items from proposal
     - Payment terms (Net 30, etc.)
     - Invoice number generation
   
3. **Document Attachment:**
   - Can we attach PDF to invoice?
   - Size limits?
   - Format requirements?

4. **Payment Tracking:**
   - Webhook support for payment status?
   - How to sync payment status back to our system?

##### Phase 3: Implementation Plan
```typescript
// Proposed flow
1. Admin clicks "Send to Bill.com" on approved proposal
2. System generates PDF of proposal
3. API call to Bill.com:
   - Create/find customer
   - Create invoice with:
     - Total amount
     - Due date
     - Attached PDF as backup doc
   - Send invoice to customer
4. Store Bill.com invoice ID in proposals table
5. Set up webhooks for payment tracking
```

#### API Research Tasks:
- [ ] Review Bill.com API documentation
- [ ] Check rate limits and pricing
- [ ] Verify PDF attachment capabilities
- [ ] Understand customer creation/matching logic
- [ ] Research webhook events available
- [ ] Check if batch operations are supported

#### Database Updates for Bill.com:
```sql
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS billcom_invoice_id VARCHAR(255);
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS billcom_invoice_number VARCHAR(100);
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS billcom_invoice_status VARCHAR(50);
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS billcom_synced_at TIMESTAMP;
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS billcom_invoice_url TEXT;
```

#### UI Changes Required:
1. Add "Send to Bill.com" button in proposal view (after approval)
2. Show Bill.com invoice status/number when synced
3. Add "View in Bill.com" link when invoice exists
4. Status indicators for sync state

### 4. Testing Checklist Before Implementation
- [ ] Verify job status updates work for both admin and technician
- [ ] Confirm time tracking totals are accurate
- [ ] Test view preference persistence
- [ ] Validate Bill.com sandbox environment
- [ ] Test PDF generation quality
- [ ] Verify QuickBooks sync (with client's accountant)

### 5. Priority Order
1. **HIGH:** Job status buttons (Work Started, Rough-in, Final)
2. **HIGH:** Show technician hours in assigned box
3. **MEDIUM:** View preference memory for technician
4. **HIGH:** Bill.com research and planning
5. **MEDIUM:** Bill.com implementation after approval

### 6. Questions for Client
1. What specific information should appear on Bill.com invoices?
2. Payment terms preferences (Net 30, Due on receipt, etc.)?
3. Should we auto-send invoices or require manual approval?
4. How to handle partial payments in Bill.com?
5. Need access to Bill.com sandbox for testing?

---
**IMPORTANT:** Do not start Bill.com implementation until:
1. Client provides API credentials
2. We understand their exact workflow
3. Testing environment is set up
4. Accountant confirms QuickBooks mapping requirements

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

### 5. Job Creation Rules
- Jobs can be created from any proposal (regardless of status)
- One job per proposal maximum (prevents duplicates)
- If job is deleted, proposal can create new job
- Database checks for existing job before allowing creation

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
**This document represents the current state and next requirements for Service Pro HVAC System as of August 29, 2025.

## Summary of Today's Complete Session:

### ✅ Major Accomplishments:
1. **Payment System Overhaul**
   - Implemented cascading payment logic
   - Fixed database constraints and triggers
   - Added manual payment recording with check images
   - Created comprehensive payment tracking UI

2. **Customer Proposal Sync**
   - Synced payment data between admin and customer views
   - Added remaining balance calculations
   - Implemented payment history tracking

3. **UI/UX Improvements**
   - Single column layouts for better readability
   - Check image viewing with modal
   - Customer link with clipboard copy
   - Improved button organization

4. **Business Logic Fixes**
   - Create Job button based on existing job check
   - Payment cascading with overflow protection
   - Status updates with proper validation

### 🔜 Next Session Focus:
1. **Technician workflow improvements** (job status buttons)
2. **Time tracking display** in assigned technicians
3. **View preference persistence**
4. **Bill.com API research and implementation planning**

The system is now production-ready for current features. Next session will focus on technician experience and Bill.com integration.**