# Payment Routing & Status Management

## CRITICAL: DO NOT MODIFY THIS PAYMENT FLOW

### Payment Flow Architecture

#### 1. Payment Creation (`/api/create-payment`)
- Creates Stripe checkout session
- Includes proposal_id, payment_stage, and session_id in success URL
- Success URL: `/api/payment-success?proposal_id={id}&payment_stage={stage}&session_id={session_id}`
- Cancel URL: `/proposal/view/{token}?payment=cancelled`

#### 2. Payment Success Handler (`/api/payment-success`)
- Triggered by Stripe redirect after successful payment
- Updates payment timestamps based on stage:
  - `deposit` → updates `deposit_paid_at`
  - `roughin` → updates `progress_paid_at`
  - `final` → updates `final_paid_at`
- Calculates and updates `total_paid`
- Logs payment to `payments` table
- Redirects back to proposal view with success indicator

#### 3. Proposal View Updates
- Auto-refreshes data when `?payment=success` in URL
- Shows payment status with checkmark for paid stages
- Unlocks next payment stage automatically
- Progressive unlocking: Deposit → Rough-in → Final

### Status Values Based on Payment Progress

1. **"approved"** - Proposal approved, no payments made
2. **"deposit_paid"** - 50% deposit payment completed
3. **"progress_paid"** - 30% rough-in payment completed
4. **"final_paid"** - All payments completed

### Database Fields

#### Payment Timestamps (DO NOT RENAME)
- `deposit_paid_at` - Timestamp when deposit paid
- `progress_paid_at` - Timestamp when rough-in paid
- `final_paid_at` - Timestamp when final paid

#### Payment Amounts (DO NOT RENAME)
- `deposit_amount` - 50% of total
- `progress_payment_amount` - 30% of total
- `final_payment_amount` - 20% of total
- `total_paid` - Running total of payments made

### Manual Status Updates
Admin can manually update status through proposal edit form for cash payments.

### Testing Payment Flow
1. Create proposal with services
2. Send to customer
3. Customer approves → status = "approved"
4. Customer pays deposit → status = "deposit_paid"
5. Customer pays rough-in → status = "progress_paid"
6. Customer pays final → status = "final_paid"
