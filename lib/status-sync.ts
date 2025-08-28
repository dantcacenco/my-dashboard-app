// Status synchronization utilities for jobs and proposals

export const PROPOSAL_STATUSES = {
  DRAFT: 'draft',
  SENT: 'sent', 
  APPROVED: 'approved',
  REJECTED: 'rejected',
  DEPOSIT_PAID: 'deposit paid',
  ROUGH_IN_PAID: 'rough-in paid',
  FINAL_PAID: 'final paid',
  COMPLETED: 'completed'
} as const

export const JOB_STATUSES = {
  NOT_SCHEDULED: 'not_scheduled',
  SCHEDULED: 'scheduled', 
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled'
} as const

/**
 * Maps proposal status to corresponding job status
 */
export function getJobStatusFromProposal(proposalStatus: string): string {
  switch (proposalStatus) {
    case PROPOSAL_STATUSES.APPROVED:
    case PROPOSAL_STATUSES.DEPOSIT_PAID:
      return JOB_STATUSES.SCHEDULED
    case PROPOSAL_STATUSES.ROUGH_IN_PAID:
    case PROPOSAL_STATUSES.FINAL_PAID:
      return JOB_STATUSES.IN_PROGRESS
    case PROPOSAL_STATUSES.COMPLETED:
      return JOB_STATUSES.COMPLETED
    case PROPOSAL_STATUSES.REJECTED:
      return JOB_STATUSES.CANCELLED
    default:
      return JOB_STATUSES.NOT_SCHEDULED
  }
}

/**
 * Maps job status to corresponding proposal status
 */
export function getProposalStatusFromJob(jobStatus: string): string {
  switch (jobStatus) {
    case JOB_STATUSES.SCHEDULED:
      return PROPOSAL_STATUSES.APPROVED
    case JOB_STATUSES.IN_PROGRESS:
      return PROPOSAL_STATUSES.ROUGH_IN_PAID // Assume work started means rough-in payment made
    case JOB_STATUSES.COMPLETED:
      return PROPOSAL_STATUSES.COMPLETED
    case JOB_STATUSES.CANCELLED:
      return PROPOSAL_STATUSES.REJECTED
    default:
      return PROPOSAL_STATUSES.DRAFT
  }
}

/**
 * Gets the display status that should be shown to users
 */
export function getUnifiedDisplayStatus(jobStatus: string, proposalStatus: string): string {
  // If there's a proposal, prioritize its payment statuses for better visibility
  if (proposalStatus) {
    // Payment-specific statuses from proposal take priority
    switch (proposalStatus) {
      case PROPOSAL_STATUSES.COMPLETED:
        return 'Completed'
      case PROPOSAL_STATUSES.FINAL_PAID:
        return 'Final Payment Complete'
      case PROPOSAL_STATUSES.ROUGH_IN_PAID:
        return 'Rough-In Paid'
      case PROPOSAL_STATUSES.DEPOSIT_PAID:
        return 'Deposit Paid'
      case PROPOSAL_STATUSES.APPROVED:
        return 'Approved'
      case PROPOSAL_STATUSES.REJECTED:
        return 'Rejected'
      case PROPOSAL_STATUSES.SENT:
        return 'Sent'
      case PROPOSAL_STATUSES.DRAFT:
        return 'Draft'
    }
  }
  
  // Fall back to job status if no proposal or unrecognized proposal status
  switch (jobStatus) {
    case JOB_STATUSES.COMPLETED:
      return 'Completed'
    case JOB_STATUSES.IN_PROGRESS:
      return 'In Progress'
    case JOB_STATUSES.SCHEDULED:
      return 'Scheduled'
    case JOB_STATUSES.CANCELLED:
      return 'Cancelled'
    case JOB_STATUSES.NOT_SCHEDULED:
      return 'Not Scheduled'
    default:
      return jobStatus.charAt(0).toUpperCase() + jobStatus.slice(1).replace('_', ' ')
  }
}

/**
 * Synchronize job and proposal statuses bidirectionally
 */
export async function syncJobProposalStatus(
  supabase: any,
  jobId: string,
  proposalId: string,
  newStatus: string,
  updatedBy: 'job' | 'proposal'
) {
  try {
    if (updatedBy === 'job') {
      // Job status changed, update proposal accordingly
      const newProposalStatus = getProposalStatusFromJob(newStatus)
      
      await supabase
        .from('proposals')
        .update({ status: newProposalStatus })
        .eq('id', proposalId)
        
      console.log(`Synced proposal ${proposalId}: ${newProposalStatus} (from job: ${newStatus})`)
      
    } else {
      // Proposal status changed, update job accordingly  
      const newJobStatus = getJobStatusFromProposal(newStatus)
      
      await supabase
        .from('jobs')
        .update({ status: newJobStatus })
        .eq('id', jobId)
        
      console.log(`Synced job ${jobId}: ${newJobStatus} (from proposal: ${newStatus})`)
    }
  } catch (error) {
    console.error('Error syncing job/proposal status:', error)
    throw error
  }
}

