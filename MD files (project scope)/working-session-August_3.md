# Working Session - January 28, 2025
## Service Pro Field Service Management - Current State & Next Steps

**Status**: Customer display bug fixed ✅  
**Tech Stack**: Next.js 15, Supabase, Stripe, Vercel  
**Current Branch**: main

---

## 🎯 **Completed**
- ✅ Customer data displays correctly in proposals table
- ✅ RLS policies fixed for customer access
- ✅ Supabase query returns customer as object (not array)

---

## 🚨 **Priority Tasks**

### **TASK 1: Customer Token-Based Access (No Auth Required)**
**Problem**: Customers must sign in to view proposals  
**Required**: Access via direct link in private/incognito browser without authentication

**Test**: 
- Open proposal link in private browser
- Should display without login prompt
- If already logged in, should also work

**Files to modify**:
- `lib/supabase/middleware.ts` - Add public paths
- `app/proposal/layout.tsx` - Create minimal layout without nav

### **TASK 2: Multi-Stage Payment System**
**Problem**: Single payment flow with basic success page  
**Required**: 3-stage payment interface after approval

**Flow**:
1. Customer approves proposal → "Approve Proposal" box disappears
2. Three payment boxes appear:
   - 50% Deposit - Green "Pay $X" button (active)
   - 30% Rough In - Greyed out (locked)
   - 20% Final - Greyed out (locked)
3. Progress bar shows total paid percentage
4. After deposit paid:
   - Proposal status → "paid deposit"
   - Dashboard revenue updates
   - 30% button becomes active
5. After rough in paid:
   - Status → "paid rough in"
   - 20% button becomes active
6. All payments tracked via Stripe webhooks

**Database columns needed**:
- deposit_paid_at, progress_paid_at, final_paid_at
- deposit_amount, progress_amount, final_amount
- total_paid
- current_payment_stage

---

## 📁 **File Structure**
```
app/
├── proposals/
│   ├── page.tsx
│   ├── ProposalsList.tsx
│   ├── [id]/
│   │   ├── page.tsx
│   │   ├── ProposalView.tsx
│   │   ├── SendProposal.tsx
│   │   └── edit/
│   └── new/
├── proposal/
│   ├── view/
│   │   └── [token]/
│   │       ├── page.tsx
│   │       └── CustomerProposalView.tsx
│   └── payment-success/
│       ├── page.tsx
│       └── PaymentSuccessView.tsx
├── api/
│   ├── create-payment/
│   ├── proposal-approval/
│   ├── payment-notification/
│   └── stripe/
│       └── webhook/
lib/
├── supabase/
│   ├── middleware.ts
│   ├── server.ts
│   └── client.ts
└── config/
    └── email.ts
```

---

## 🗄️ **Database Context Required**

**IMPORTANT**: When starting a new chat, Claude needs:

1. **Current database schema from Supabase**:
   - Run this SQL and provide output:
   ```sql
   SELECT column_name, data_type, is_nullable 
   FROM information_schema.columns 
   WHERE table_name = 'proposals' 
   ORDER BY ordinal_position;
   ```

2. **Key facts**:
   - Supabase joins return OBJECTS not arrays (customers, not customers[0])
   - RLS is enabled on both proposals and customers tables
   - customer_view_token is used for public access
   - All payment stage columns already exist in database

3. **Current issues**:
   - Middleware redirects all unauthenticated users to /auth/signin
   - Payment success page shows instead of returning to proposal
   - No multi-stage payment UI exists yet

---

## 🔧 **Development Guidelines**

### **Response Format**
- ONE comprehensive shell script per response
- Replace ENTIRE files (no sed/grep partial updates)
- Include error checking
- Auto-commit and push to GitHub
- Non-verbose, direct solutions only

### **Script Template**
```bash
#!/bin/bash
echo "🔧 [Task description]..."

# Create backup
cp [file] [file].backup

# Write complete file
cat > [file] << 'EOF'
[COMPLETE FILE CONTENT]
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error writing file"
    exit 1
fi

# Commit and push
git add .
git commit -m "fix: [clear description]"
git push origin main

echo "✅ Complete!"
```

### **Testing**
- Always test in private/incognito browser
- Check console for errors
- Verify database updates
- Confirm Stripe webhooks fire

---

## 💡 **Context for New Chats**

When starting fresh, provide:
1. This working session document
2. Current database schema
3. Any error messages
4. Which task you're working on

Ask Claude: "Based on the working session doc, what database information do you need to proceed?"

**Remember**: 
- Customer data is an OBJECT, not array
- Use complete file replacements
- One script solution only
- Test everything in private browser