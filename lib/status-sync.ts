// Status synchronization utilities for jobs and proposals

export const PROPOSAL_STATUSES = {
  DRAFT: 'draft',
  SENT: 'sent', 
  VIEWED: 'viewed',
  APPROVED: 'approved',
  REJECTED: 'rejected'
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
      return JOB_STATUSES.SCHEDULED
    case PROPOSAL_STATUSES.REJECTED:
      return JOB_STATUSES.CANCELLED
    default:
      return JOB_STATUSES.NOT_SCHEDULED
  }
}

/**
 * Maps job status to corresponding proposal status
 * Note: Proposals stay "approved" even when jobs are completed
 * The UI will show unified status based on job status
 */
export function getProposalStatusFromJob(jobStatus: string): string {
  switch (jobStatus) {
    case JOB_STATUSES.COMPLETED:
      return PROPOSAL_STATUSES.APPROVED // Keep approved, show "Completed" in UI
    case JOB_STATUSES.CANCELLED:
      return PROPOSAL_STATUSES.REJECTED
    case JOB_STATUSES.SCHEDULED:
    case JOB_STATUSES.IN_PROGRESS:
      return PROPOSAL_STATUSES.APPROVED
    default:
      return PROPOSAL_STATUSES.APPROVED
  }
}

/**
 * Gets the display status that should be shown to users
 * This ensures both job and proposal show consistent status
 */
export function getUnifiedDisplayStatus(jobStatus: string, proposalStatus: string): string {
  // Priority: Job status takes precedence for display
  if (jobStatus === JOB_STATUSES.COMPLETED) {
    return 'Completed'
  }
  
  if (jobStatus === JOB_STATUSES.CANCELLED) {
    return 'Cancelled'
  }
  
  if (proposalStatus === PROPOSAL_STATUSES.REJECTED) {
    return 'Cancelled'
  }
  
  // For active work
  if (proposalStatus === PROPOSAL_STATUSES.APPROVED) {
    switch (jobStatus) {
      case JOB_STATUSES.SCHEDULED:
        return 'Scheduled'
      case JOB_STATUSES.IN_PROGRESS:
        return 'In Progress'
      default:
        return 'Approved'
    }
  }
  
  // Pre-work statuses
  switch (proposalStatus) {
    case PROPOSAL_STATUSES.DRAFT:
      return 'Draft'
    case PROPOSAL_STATUSES.SENT:
      return 'Sent'
    case PROPOSAL_STATUSES.VIEWED:
      return 'Viewed'
    case PROPOSAL_STATUSES.APPROVED:
      return 'Approved'
    case PROPOSAL_STATUSES.REJECTED:
      return 'Rejected'
    default:
      return jobStatus.charAt(0).toUpperCase() + jobStatus.slice(1).replace('_', ' ')
  }
}

/**
 * Synchronize job and proposal statuses in database
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
        
      console.log(`Updated proposal ${proposalId} status to ${newProposalStatus} based on job status ${newStatus}`)
      
    } else {
      // Proposal status changed, update job accordingly  
      const newJobStatus = getJobStatusFromProposal(newStatus)
      
      await supabase
        .from('jobs')
        .update({ status: newJobStatus })
        .eq('id', jobId)
        
      console.log(`Updated job ${jobId} status to ${newJobStatus} based on proposal status ${newStatus}`)
    }
  } catch (error) {
    console.error('Error syncing job/proposal status:', error)
    throw error
  }
}
