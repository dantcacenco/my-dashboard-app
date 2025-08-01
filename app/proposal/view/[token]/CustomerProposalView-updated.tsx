// Add this import at the top of CustomerProposalView.tsx
import MultiStagePayment from './MultiStagePayment'

// In the CustomerProposalView component, add this after the approval section:
// (This shows where to add the component - you'll need to manually integrate it)

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
