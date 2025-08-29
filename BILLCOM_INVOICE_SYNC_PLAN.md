# Bill.com Invoice Sync Integration Plan (REVISED)

## Critical Understanding Change
**Bill.com is for INVOICING ONLY, not payment processing**
- Client uses Bill.com to generate and send invoices to customers
- Bill.com is B2B focused and NOT suitable for consumer payments
- Keep Stripe for actual payment processing
- Use Bill.com purely for invoice generation and tracking

## Current Client Workflow
1. Client creates proposal in Service Pro
2. When approved, they manually create invoice in Bill.com
3. Send invoice to customer from Bill.com
4. Customer pays via check/cash or online (Stripe)
5. Client manually reconciles in both systems

## Proposed Automated Workflow
1. Proposal approved in Service Pro
2. **NEW:** "Send to Bill.com" button creates invoice automatically
3. Invoice sent from Bill.com (their existing process)
4. Payment collected via:
   - Stripe (online payments)
   - Manual recording (cash/check)
5. Status syncs between systems

## Implementation Plan (Simplified)

### Phase 1: Add Invoice Sync UI
```typescript
// Add to ProposalView.tsx buttons section
<Button 
  onClick={() => handleSendToBillcom()} 
  variant="outline" 
  size="sm"
  disabled={proposal.status !== 'approved' || proposal.billcom_invoice_id}
>
  <FileText className="h-4 w-4 mr-1" />
  {proposal.billcom_invoice_id ? 'Sent to Bill.com' : 'Send to Bill.com'}
</Button>
```

### Phase 2: Database Updates
```sql
-- Add to proposals table
ALTER TABLE proposals 
ADD COLUMN billcom_invoice_id VARCHAR(255),
ADD COLUMN billcom_invoice_number VARCHAR(100),
ADD COLUMN billcom_sync_status VARCHAR(50),
ADD COLUMN billcom_synced_at TIMESTAMP;
```

### Phase 3: API Integration (Minimal)

#### Create Invoice in Bill.com
```typescript
// /app/api/billcom/create-invoice/route.ts
export async function POST(req: Request) {
  const { proposalId } = await req.json()
  
  // Get proposal data
  const proposal = await getProposal(proposalId)
  
  // Create invoice in Bill.com
  const billcomInvoice = await billcomClient.createInvoice({
    customerName: proposal.customer.name,
    customerEmail: proposal.customer.email,
    amount: proposal.total,
    description: proposal.title,
    lineItems: proposal.items.map(item => ({
      description: item.name,
      quantity: item.quantity,
      price: item.unit_price
    }))
  })
  
  // Store Bill.com invoice ID
  await updateProposal(proposalId, {
    billcom_invoice_id: billcomInvoice.id,
    billcom_invoice_number: billcomInvoice.number,
    billcom_sync_status: 'synced',
    billcom_synced_at: new Date()
  })
  
  return NextResponse.json({ success: true, invoiceNumber: billcomInvoice.number })
}
```

### Phase 4: Status Indicators

#### Show Invoice Status
```tsx
// In ProposalView.tsx
{proposal.billcom_invoice_id && (
  <div className="flex items-center gap-2 text-sm text-gray-600">
    <FileText className="h-4 w-4" />
    <span>Bill.com Invoice: #{proposal.billcom_invoice_number}</span>
    <Badge variant="outline" className="text-xs">
      {proposal.billcom_sync_status}
    </Badge>
  </div>
)}
```

## Key Differences from Original Plan

### What We're NOT Doing
- ❌ Replacing Stripe payment processing
- ❌ Processing payments through Bill.com
- ❌ Complex webhook integrations
- ❌ Payment stage tracking in Bill.com
- ❌ Customer payment portals in Bill.com

### What We ARE Doing
- ✅ Creating invoices in Bill.com automatically
- ✅ Tracking invoice numbers
- ✅ One-way sync (Service Pro → Bill.com)
- ✅ Keeping Stripe for payments
- ✅ Simple status tracking

## Technical Requirements

### Bill.com API Endpoints Needed (Only 2!)
1. **Create Invoice** - `POST /Crud/Create/Invoice`
2. **Read Invoice** - `GET /Crud/Read/Invoice` (optional, for status checks)

### Environment Variables
```env
BILLCOM_DEV_KEY=xxx
BILLCOM_ORG_ID=xxx
BILLCOM_USERNAME=xxx
BILLCOM_PASSWORD=xxx
```

### Simple API Client
```typescript
// /lib/billcom/client.ts
class BillcomInvoiceClient {
  private sessionId: string | null = null
  
  async authenticate() {
    // Simple auth, get session ID
  }
  
  async createInvoice(data: InvoiceData) {
    // Create invoice
    // Return invoice ID and number
  }
  
  async getInvoiceStatus(invoiceId: string) {
    // Optional: Check invoice status
  }
}
```

## UI Changes Summary

### Proposal View Page
1. Add "Send to Bill.com" button (only for approved proposals)
2. Show Bill.com invoice number if synced
3. Disable button after invoice created
4. Show sync status badge

### No Changes To
- Payment processing flow
- Stripe integration
- Customer payment experience
- Manual payment recording
- Email system

## Implementation Timeline (Much Shorter!)

### Week 1: Setup & Research
- Get Bill.com API credentials from client
- Test API in sandbox
- Understand their invoice format

### Week 2: Build Integration
- Add database columns
- Create API route
- Build simple client

### Week 3: UI & Testing
- Add button to proposal view
- Test invoice creation
- Add status indicators

### Week 4: Deploy
- Production credentials
- Test with real data
- Monitor and adjust

## Benefits of This Approach

### For Client
- Eliminates manual invoice creation
- Keeps their existing Bill.com workflow
- No disruption to payment processing
- Easy to understand and use

### For Development
- Much simpler implementation
- No payment processing complexity
- Minimal risk
- Quick to build and deploy

## Next Immediate Steps

1. **Ask Client For:**
   - Bill.com API credentials
   - Sample invoice from their Bill.com
   - Confirmation this matches their workflow

2. **Development Tasks:**
   - Add "Send to Bill.com" button to proposal view
   - Create simple API integration
   - Add invoice tracking fields

3. **Testing:**
   - Create test invoice in sandbox
   - Verify format matches client needs
   - Ensure no impact on payment flow

## Important Notes

### What Client Keeps Doing
- Using Bill.com for invoice management
- Using Stripe for online payments
- Recording manual payments in Service Pro
- Their existing accounting workflow

### What Gets Automated
- Invoice creation from approved proposals
- Invoice number tracking
- Basic sync status

### Future Considerations
- Could add invoice status webhooks later
- Could sync payment status from Bill.com
- Could add bulk invoice creation
- But START SIMPLE!

## Conclusion

This revised approach is **10x simpler** than the original plan. Instead of replacing the entire payment system, we're just automating one manual step: creating invoices in Bill.com. This gives the client immediate value with minimal risk and complexity.

**Key Insight:** Bill.com is their invoicing tool, not their payment processor. We're enhancing their workflow, not replacing it.