# Service Pro - HVAC Field Service Management System
## Comprehensive Project Scope Document

**Last Updated**: January 2025  
**Version**: 2.0  
**Tech Stack**: Next.js 15.4.3, Supabase, Stripe, Vercel, Resend  

---

## 🎯 PROJECT OVERVIEW

Service Pro is a multi-tenant SaaS application for HVAC field service businesses, similar to Housecall Pro. It manages the complete workflow from proposal creation to payment collection with a focus on customer self-service and multi-stage payment processing.

### Core Business Flow
1. **Admin** creates proposals with services and optional add-ons
2. **Customer** receives proposal link via email (no login required)
3. **Customer** reviews, selects add-ons, approves/rejects proposal
4. **Upon approval**, customer pays in 3 stages (50% deposit, 30% rough-in, 20% final)
5. **System** tracks payments, creates jobs, generates invoices

---

## 🗄️ DATABASE STRUCTURE (ACTUAL FROM SUPABASE)

### Key Tables

#### `proposals` Table
Critical columns with naming inconsistencies (BOTH exist):
- `deposit_amount` - 50% deposit amount
- `progress_payment_amount` AND `progress_amount` - 30% rough-in amount
- `final_payment_amount` AND `final_amount` - 20% final amount
- `total` - Total proposal amount (NOT `total_amount`)
- `subtotal` - Amount before tax
- `tax_amount` - Tax amount
- `customer_view_token` - Unique token for customer access
- `payment_stage` - Current payment stage ('deposit', 'roughin', 'final', 'complete')
- `deposit_paid_at`, `progress_paid_at`, `final_paid_at` - Payment timestamps
- `total_paid` - Running total of payments received

#### `payment_stages` Table (EXISTS)
- `id`, `proposal_id`, `stage`
- `percentage`, `amount`, `due_date`
- `paid`, `paid_at`
- `stripe_session_id`, `stripe_payment_intent_id`
- `created_at`, `updated_at`

#### `customers` Table
- Standard fields: `id`, `name`, `email`, `phone`, `address`
- `created_by`, `updated_by` - User references

#### `profiles` Table
- `role` field contains: 'boss', 'admin', or 'technician'
- Current user (dantcacenco@gmail.com) has role: 'boss'

### Critical Data Structure Facts
1. **Supabase joins return OBJECTS not arrays**
   - ✅ CORRECT: `proposal.customers.name`
   - ❌ WRONG: `proposal.customers[0].name`
2. **User role is 'boss' not 'admin'** - but code should check for both
3. **Both column name variants exist** in proposals table

---

## 📁 PROJECT STRUCTURE

```
/app
├── (authenticated)/          # Protected routes requiring login
│   ├── proposals/           # Admin proposal management
│   │   ├── page.tsx        # List all proposals
│   │   ├── ProposalsList.tsx
│   │   ├── [id]/
│   │   │   ├── page.tsx    # View single proposal
│   │   │   ├── ProposalView.tsx
│   │   │   ├── SendProposal.tsx
│   │   │   ├── PaymentStages.tsx
│   │   │   └── edit/       # Edit proposal
│   │   └── new/            # Create proposal
│   ├── dashboard/          # Admin dashboard
│   ├── customers/          # Customer management
│   ├── jobs/              # Job tracking
│   ├── invoices/          # Invoice management
│   └── technicians/       # Technician management
│
├── proposal/               # PUBLIC customer-facing routes (no auth)
│   ├── view/
│   │   └── [token]/       # Token-based proposal viewing
│   │       ├── page.tsx
│   │       └── CustomerProposalView.tsx
│   └── payment-success/   # Stripe payment return
│
├── api/
│   ├── create-payment/    # Stripe checkout session creation
│   ├── proposal-approval/ # Handle approval/rejection
│   ├── send-proposal/     # Email proposal to customer
│   └── stripe/
│       └── webhook/       # Process Stripe events
│
/components
├── PaymentStages.tsx      # Reusable payment stages display
├── MultiStagePayment.tsx  # Multi-stage payment handler
└── SendProposal.tsx       # Send proposal modal
```

---

## 💰 PAYMENT FLOW IMPLEMENTATION

### Current Implementation Status
1. ✅ Stripe integration configured (API version: '2025-07-30.basil')
2. ✅ Multi-stage payment UI components exist
3. ✅ Payment stages table exists in database
4. ⚠️ Payment flow partially implemented but needs consolidation

### Desired Payment Flow
1. **Customer views proposal** → Shows "Approve Proposal" button
2. **Customer approves** → Page refreshes, approval button disappears
3. **Payment stages appear**:
   - 50% Deposit: ✅ Active "Pay Now" button
   - 30% Rough-in: 🔒 Grayed out (locked)
   - 20% Final: 🔒 Grayed out (locked)
4. **After deposit paid** → Returns to same page:
   - Deposit shows as paid ✅
   - Rough-in becomes active
5. **Progressive unlocking** continues through all stages
6. **All payments complete** → Status changes to 'complete'

### Payment Technical Details
- Amounts stored in DOLLARS (not cents) in database
- Stripe requires amounts in CENTS (multiply by 100)
- Return URL after payment: `/proposal/view/[token]`
- Each payment updates both `proposals` and `payment_stages` tables

---

## 🔐 AUTHENTICATION & AUTHORIZATION

### User Roles
- **boss/admin**: Full system access (treat these as equivalent)
- **technician**: Limited access to assigned jobs
- **customer**: No login required, token-based proposal access

### Route Protection
- `/app/(authenticated)/*`: Requires login and boss/admin role
- `/app/proposal/*`: PUBLIC routes, no authentication required
- Middleware must allow public paths for customer access

### Role Check Pattern
```typescript
// Always check for BOTH roles
if (profile?.role !== 'admin' && profile?.role !== 'boss') {
  redirect('/')
}
```

---

## 🚀 ENVIRONMENT CONFIGURATION

### Required Environment Variables (All configured in Vercel)
```
# Supabase
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY

# Stripe
STRIPE_SECRET_KEY
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
STRIPE_WEBHOOK_SECRET

# Resend Email
RESEND_API_KEY
EMAIL_FROM=onboarding@resend.dev
BUSINESS_EMAIL=dantcacenco@gmail.com

# Optional but recommended
NEXT_PUBLIC_BASE_URL
```

---

## ⚠️ CRITICAL IMPLEMENTATION NOTES

### Database Column Usage Rules
1. **Use the longer column names** for consistency:
   - Use `progress_payment_amount` not `progress_amount`
   - Use `final_payment_amount` not `final_amount`
   - Use `total` not `total_amount`

2. **Customer Data Access**:
   - Customers is an OBJECT: `proposal.customers.name`
   - NOT an array: ~~`proposal.customers[0].name`~~

3. **Role Checking**:
   - Always check for both 'boss' and 'admin'
   - Plan to migrate all to 'admin' in future

4. **Payment Processing**:
   - Database stores amounts in dollars
   - Stripe needs cents (multiply by 100)
   - Use lowercase stage names: 'deposit', 'roughin', 'final'

5. **Testing Requirements**:
   - Always test customer flows in incognito/private browser
   - Verify token-based access works without login
   - Check payment flow returns to proposal view

---

## 🎯 CURRENT PRIORITIES

### Immediate Issues to Fix
1. **Consolidate payment flow** - Single implementation in CustomerProposalView
2. **Update all role checks** to use 'admin' consistently
3. **Fix column name inconsistencies** throughout codebase
4. **Ensure public routes** work without authentication

### Next Phase Features
1. Job creation from approved proposals
2. Invoice generation from completed jobs
3. Technician assignment and scheduling
4. Email notifications for payment reminders
5. Migration to Bill.com for payment processing

---

## 📝 DEVELOPMENT GUIDELINES

### Code Standards
- Single comprehensive .sh scripts for all changes
- Complete file replacements (no sed/grep)
- Test builds before committing
- Clear, descriptive commit messages
- Always push to main branch

### Testing Protocol
1. Run TypeScript check: `npx tsc --noEmit`
2. Test build: `npm run build`
3. Test in private browser for customer flows
4. Verify Stripe webhooks fire correctly
5. Check database updates

### File Change Strategy
- Replace entire files to avoid conflicts
- Keep backups of working versions
- Test after every major change
- Commit frequently with clear messages

---

## 🔄 KNOWN ISSUES & SOLUTIONS

### Issue: Payment stages not displaying
**Solution**: Ensure `payment_stages` table is populated after proposal approval

### Issue: Customer can't access proposal
**Solution**: Check middleware allows `/proposal/view/*` as public path

### Issue: Role authorization failures
**Solution**: Update all checks to include both 'boss' and 'admin'

### Issue: Payment amounts incorrect
**Solution**: Use correct column names and ensure dollar/cent conversion

---

## 📚 REFERENCE QUERIES

### Useful SQL Queries
```sql
-- Check user role
SELECT role FROM profiles 
WHERE email = 'dantcacenco@gmail.com';

-- View proposal with customer
SELECT p.*, c.* 
FROM proposals p 
LEFT JOIN customers c ON p.customer_id = c.id 
LIMIT 1;

-- Check payment stages
SELECT * FROM payment_stages 
WHERE proposal_id = '[PROPOSAL_ID]'
ORDER BY stage;
```

---

This document represents the authoritative source for project understanding. Any conflicting information in other documents should defer to this scope.
