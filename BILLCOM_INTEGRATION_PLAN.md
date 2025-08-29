# Bill.com API Integration Plan

## Overview
Plan to replace Stripe with Bill.com for payment processing in the Service Pro HVAC Management System.

## Current State
- **Payment Provider:** Stripe
- **Payment Model:** 3-stage (50% deposit, 30% rough-in, 20% final)
- **Integration Points:**
  - `/api/create-payment/route.ts` - Creates checkout sessions
  - `/api/stripe/webhook/route.ts` - Processes payment events
  - `/api/payment-success/route.ts` - Handles success redirects

## Bill.com API Research

### Authentication
- **OAuth 2.0** flow required
- API Keys: `devKey` and `sessionId` for requests
- Base URL: `https://api.bill.com/api/v2/`
- Sandbox available for testing

### Key Endpoints Needed

#### 1. Customer Management
```
POST /Crud/Create/Customer
GET /Crud/Read/Customer
```
- Create customer profiles
- Sync with our `customers` table

#### 2. Invoice Creation
```
POST /Crud/Create/Invoice
GET /Crud/Read/Invoice
```
- Create invoices from approved proposals
- Support partial payment schedules

#### 3. Payment Processing
```
POST /SendPayment
GET /GetPaymentStatus
```
- Process customer payments
- Track payment status

#### 4. Webhooks
```
POST /webhooks/subscribe
```
- Payment received events
- Invoice status changes

## Implementation Strategy

### Phase 1: Environment Setup
1. **Environment Variables**
```env
BILLCOM_DEV_KEY=
BILLCOM_ORG_ID=
BILLCOM_USERNAME=
BILLCOM_PASSWORD=
BILLCOM_WEBHOOK_SECRET=
PAYMENT_PROVIDER=billcom # or stripe
```

2. **Configuration Toggle**
- Add environment variable to switch between Stripe/Bill.com
- Maintain backward compatibility

### Phase 2: API Client Creation
Create `/lib/billcom/` directory:
```
/lib/billcom/
├── client.ts          # API client with auth
├── customers.ts       # Customer operations
├── invoices.ts        # Invoice operations
├── payments.ts        # Payment operations
└── types.ts          # TypeScript interfaces
```

### Phase 3: Core Functions

#### Authentication Handler
```typescript
// /lib/billcom/client.ts
class BillcomClient {
  async authenticate() {
    // Get sessionId using devKey
    // Store and refresh as needed
  }
  
  async request(endpoint: string, data: any) {
    // Wrapper for all API calls
    // Handles auth and errors
  }
}
```

#### Invoice Creation
```typescript
// /lib/billcom/invoices.ts
async function createInvoiceFromProposal(proposal: Proposal) {
  // Map proposal to Bill.com invoice format
  // Set payment terms for 3-stage payments
  // Return invoice ID
}
```

#### Payment Tracking
```typescript
// /lib/billcom/payments.ts
async function trackPaymentStages(invoiceId: string) {
  // Monitor deposit (50%)
  // Monitor rough-in (30%)
  // Monitor final (20%)
  // Update database accordingly
}
```

### Phase 4: Database Updates

#### New Tables Needed
```sql
-- Bill.com specific data
CREATE TABLE billcom_sync (
  id UUID PRIMARY KEY,
  proposal_id UUID REFERENCES proposals(id),
  billcom_customer_id VARCHAR(255),
  billcom_invoice_id VARCHAR(255),
  sync_status VARCHAR(50),
  last_synced_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### Migration Path
- Keep existing Stripe fields
- Add Bill.com fields in parallel
- Use `payment_provider` field to determine active system

### Phase 5: API Route Updates

#### 1. Create Payment Route
```typescript
// /api/create-payment/route.ts
export async function POST(req: Request) {
  const provider = process.env.PAYMENT_PROVIDER || 'stripe'
  
  if (provider === 'billcom') {
    return createBillcomInvoice(req)
  } else {
    return createStripeSession(req)
  }
}
```

#### 2. Webhook Handler
```typescript
// /api/billcom/webhook/route.ts
export async function POST(req: Request) {
  // Verify webhook signature
  // Process Bill.com events
  // Update payment stages
  // Sync with our database
}
```

### Phase 6: UI Updates

#### Minimal UI Changes
- Payment status displays remain the same
- Add Bill.com invoice link where Stripe link was
- Keep existing payment stage UI

#### Admin Features
- Add Bill.com sync status indicator
- Show invoice number from Bill.com
- Add manual sync button if needed

## Migration Plan

### Step 1: Parallel Implementation
1. Build Bill.com integration alongside Stripe
2. Use feature flag to control which is active
3. Test thoroughly in sandbox

### Step 2: Pilot Testing
1. Select test customers
2. Process their payments through Bill.com
3. Monitor for issues
4. Gather feedback

### Step 3: Gradual Rollout
1. New proposals use Bill.com
2. Existing Stripe payments continue
3. Monitor both systems

### Step 4: Full Migration
1. Switch all new payments to Bill.com
2. Complete remaining Stripe payments
3. Archive Stripe integration

## Bill.com Advantages

### For Business
- **Better cash flow management**
- **Automated AR/AP**
- **ACH payments (lower fees than cards)**
- **Integration with accounting software**
- **Better reporting and reconciliation**

### For Customers
- **Multiple payment options** (ACH, credit card, check)
- **Payment scheduling**
- **Auto-pay capabilities**
- **Professional invoicing**

## Technical Considerations

### Rate Limits
- Bill.com API: 10,000 calls/day
- Implement caching and queuing

### Error Handling
- Retry logic for failed requests
- Fallback to manual processing
- Alert system for failures

### Security
- Secure storage of API credentials
- Webhook signature verification
- PCI compliance maintained

### Testing Strategy
1. Unit tests for all Bill.com functions
2. Integration tests with sandbox
3. End-to-end payment flow tests
4. Load testing for webhooks

## Timeline Estimate

### Week 1-2: Research & Setup
- Complete API documentation review
- Set up sandbox account
- Create initial API client

### Week 3-4: Core Implementation
- Build customer sync
- Implement invoice creation
- Set up payment tracking

### Week 5-6: Integration
- Update existing routes
- Implement webhooks
- Add database migrations

### Week 7-8: Testing
- Comprehensive testing
- Bug fixes
- Performance optimization

### Week 9-10: Rollout
- Pilot with test customers
- Monitor and adjust
- Full deployment

## Required Resources

### Development
- Bill.com sandbox account
- API documentation access
- Test customer data

### Production
- Bill.com business account
- API credentials
- Webhook endpoints
- SSL certificates

## Risks & Mitigation

### Risk 1: API Downtime
- **Mitigation:** Queue system for retry
- **Fallback:** Manual invoice creation

### Risk 2: Payment Delays
- **Mitigation:** Clear customer communication
- **Fallback:** Alternative payment methods

### Risk 3: Integration Complexity
- **Mitigation:** Phased approach
- **Fallback:** Keep Stripe as backup

## Success Metrics

### Technical
- API response time < 2s
- Webhook processing < 5s
- 99.9% uptime
- Zero payment data loss

### Business
- Reduced payment processing fees
- Faster payment collection
- Improved cash flow visibility
- Better accounting integration

## Next Steps

1. **Immediate Actions**
   - Sign up for Bill.com sandbox
   - Review detailed API documentation
   - Create proof of concept

2. **Approval Needed**
   - Budget for Bill.com subscription
   - Timeline approval
   - Resource allocation

3. **Questions to Answer**
   - Exact Bill.com pricing for our volume
   - Integration with current accounting system
   - Customer communication plan

## Code Examples

### Basic API Call
```typescript
async function createBillcomInvoice(proposalData: any) {
  const client = new BillcomClient()
  await client.authenticate()
  
  const invoice = await client.createInvoice({
    customerId: proposalData.customer_id,
    amount: proposalData.total,
    dueDate: calculateDueDate(),
    lineItems: proposalData.items,
    paymentTerms: '50% deposit, 30% rough-in, 20% final'
  })
  
  return invoice
}
```

### Webhook Processing
```typescript
async function handleBillcomWebhook(event: any) {
  switch (event.type) {
    case 'payment.received':
      await updatePaymentStage(event.invoiceId, event.amount)
      break
    case 'invoice.sent':
      await updateProposalStatus(event.invoiceId, 'sent')
      break
    // ... other events
  }
}
```

## Conclusion

Bill.com integration offers significant advantages for payment processing and accounting integration. The implementation is complex but manageable with a phased approach. The key is maintaining backward compatibility while gradually migrating to the new system.

**Recommended approach:** Start with a proof of concept, then implement in parallel with Stripe, allowing for a gradual, risk-free migration.