# Working Session - January 28, 2025
## Service Pro - Payment Flow Implementation & Role Standardization

**Current Status**: Database structure confirmed, ready for implementation  
**Priority**: Fix payment flow and standardize roles to 'admin'  
**Approach**: Single comprehensive solution per issue  

---

## 🎯 IMMEDIATE TASKS (IN ORDER)

### TASK 1: Standardize All Roles to 'admin' ✅ READY
**Problem**: Mixed use of 'boss' and 'admin' throughout codebase  
**Solution**: Update all role checks to use 'admin' and update database

**Files to modify**:
- All files in `/app/(authenticated)/` checking roles
- Update database role from 'boss' to 'admin'
- Maintain backward compatibility during transition

**Implementation**: Create `standardize-roles-to-admin.sh`

---

### TASK 2: Fix Column Name Inconsistencies ✅ READY  
**Problem**: Both `progress_amount` and `progress_payment_amount` exist  
**Solution**: Standardize on longer names throughout codebase

**Correct column names to use**:
- `progress_payment_amount` (not `progress_amount`)
- `final_payment_amount` (not `final_amount`)
- `total` (not `total_amount`)

**Implementation**: Create `fix-column-names.sh`

---

### TASK 3: Consolidate Payment Flow ✅ READY
**Problem**: Multiple payment implementations causing confusion  
**Solution**: Single unified flow in CustomerProposalView

**Requirements**:
1. Approval creates payment_stages records
2. Shows payment boxes after approval (no separate page)
3. Progressive unlocking of payment stages
4. Returns to proposal view after each payment

**Key components**:
- Merge PaymentStages display into CustomerProposalView
- Handle all payment logic in same component
- Update payment_stages table on each transaction

**Implementation**: Create `consolidate-payment-flow.sh`

---

### TASK 4: Ensure Public Route Access ✅ READY
**Problem**: Customers might be redirected to login  
**Solution**: Update middleware to allow public paths

**Public paths to allow**:
- `/proposal/view/*`
- `/proposal/payment-success`
- `/api/proposal-approval`
- `/api/create-payment`
- `/api/stripe/webhook`

**Implementation**: Create `fix-public-routes.sh`

---

## 🔄 IMPLEMENTATION SEQUENCE

### Step 1: Database & Role Update
```bash
#!/bin/bash
# First update the database role
echo "Updating database roles from 'boss' to 'admin'..."

# Create SQL update script
cat > update-roles.sql << 'EOF'
UPDATE profiles 
SET role = 'admin' 
WHERE role = 'boss';
EOF

# Then update all TypeScript files
# Complete implementation in standardize-roles-to-admin.sh
```

### Step 2: Fix Column References
```bash
#!/bin/bash
# Update all references to use correct column names
# This ensures consistency across the codebase
# Complete implementation in fix-column-names.sh
```

### Step 3: Payment Flow Consolidation
```bash
#!/bin/bash
# Merge all payment logic into CustomerProposalView
# Remove duplicate implementations
# Complete implementation in consolidate-payment-flow.sh
```

### Step 4: Public Access
```bash
#!/bin/bash
# Update middleware to allow public routes
# Test in incognito browser
# Complete implementation in fix-public-routes.sh
```

---

## 📊 CURRENT STATE SUMMARY

### What's Working
- ✅ Database structure is correct
- ✅ Both column name variants exist (backward compatible)
- ✅ Payment stages table exists
- ✅ Stripe integration configured
- ✅ Customer data returns as OBJECT (not array)

### What Needs Fixing
- ❌ Mixed role usage ('boss' vs 'admin')
- ❌ Inconsistent column name usage
- ❌ Payment flow not unified
- ❌ Public route access uncertain

### Database Facts (Confirmed)
- User role: Currently 'boss' (needs update to 'admin')
- Customer data: Returns as OBJECT
- Payment stages table: EXISTS and has correct structure
- Amount columns: Both variants exist (use longer names)

---

## 🧪 TESTING CHECKLIST

After each implementation:

### Role Testing
- [ ] Can log in as admin
- [ ] Can access all admin pages
- [ ] Technician role still works

### Payment Testing  
- [ ] Proposal approval triggers payment stages
- [ ] First payment (deposit) is immediately available
- [ ] Other stages are locked until previous paid
- [ ] Payment returns to proposal view
- [ ] Payment updates database correctly

### Customer Access Testing
- [ ] Open proposal link in incognito browser
- [ ] No login required
- [ ] Can approve proposal
- [ ] Can make payments
- [ ] Returns to proposal after payment

### Build Testing
- [ ] TypeScript compiles: `npx tsc --noEmit`
- [ ] Build succeeds: `npm run build`
- [ ] No console errors in browser

---

## 💡 IMPLEMENTATION RULES

### Critical Patterns
```typescript
// Customer access - ALWAYS an object
const customerName = proposal.customers.name; // ✅ CORRECT

// Role checking - Check for 'admin' only after update
if (profile?.role !== 'admin') { // After standardization
  redirect('/');
}

// Payment amounts - Use correct columns
const progressAmount = proposal.progress_payment_amount; // ✅
// NOT: proposal.progress_amount ❌

// Stripe amounts - Convert to cents
const stripeAmount = Math.round(dollarAmount * 100);
```

### File Replacement Strategy
1. **Never use sed/grep** for complex changes
2. **Replace entire files** to avoid conflicts
3. **Test immediately** after replacement
4. **Commit with clear message** describing the change

---

## 🚀 NEXT STEPS AFTER THESE FIXES

Once the above 4 tasks are complete:

1. **Test complete payment flow** end-to-end
2. **Create job from approved proposal** (auto or manual)
3. **Generate invoice from completed job**
4. **Add payment reminder emails**
5. **Implement technician scheduling**

---

## 📝 SESSION NOTES

### Key Decisions Made
1. Standardize all roles to 'admin' (easier to remember)
2. Use longer column names for consistency
3. Single payment flow implementation in CustomerProposalView
4. Payment stages appear on same page after approval

### Lessons Learned
1. Database structure exists - use it, don't recreate
2. Always check actual database before making assumptions
3. Test customer flows in incognito mode
4. Keep payment logic in one place

### Watch Out For
1. Don't break existing working features
2. Test role changes thoroughly
3. Ensure backward compatibility during transition
4. Always verify customer can access without login

---

## 📋 QUICK REFERENCE

### Database Connection
```javascript
const supabaseUrl = 'https://dqcxwekmehrqkigcufug.supabase.co';
// Use environment variables in production
```

### Current User
- Email: dantcacenco@gmail.com
- Current Role: 'boss' (updating to 'admin')
- ID: d59c31b1-ccce-4fe8-be8d-7295ec41f7ac

### Payment Stages
1. Deposit: 50% - Immediately available
2. Rough-in: 30% - After deposit paid
3. Final: 20% - After rough-in paid

### Stripe Configuration
- API Version: '2025-07-30.basil'
- Amounts in CENTS (multiply dollars by 100)
- Return URL: `/proposal/view/[token]`

---

**Ready to implement**: Start with Task 1 (standardize roles) and work through sequentially. Each task should be one comprehensive script that completely solves the issue.
