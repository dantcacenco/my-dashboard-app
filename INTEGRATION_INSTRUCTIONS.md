# Integration Instructions for Multi-Stage Payment

## Update CustomerProposalView.tsx

Add this import at the top:
```typescript
import MultiStagePayment from './MultiStagePayment'
```

Add this after the approval section (around line 320):
```typescript
{proposal.status === 'approved' && (
  <MultiStagePayment
    proposalId={proposal.id}
    proposalNumber={proposal.proposal_number}
    customerName={proposal.customers[0]?.name || ''}
    customerEmail={proposal.customers[0]?.email || ''}
    proposal={proposal}
    onPaymentComplete={() => window.location.reload()}
  />
)}
```

## Remove or hide the old PaymentMethods component
Comment out or remove the PaymentMethods component that appears after approval.

## Test the flow:
1. Customer views proposal
2. Customer approves proposal
3. Multi-stage payment UI appears
4. Customer can pay each stage in sequence
5. Progress bar updates after each payment
