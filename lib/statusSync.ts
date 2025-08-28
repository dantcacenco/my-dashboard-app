// Status mapping utilities for job-proposal synchronization

export interface StatusMapping {
  display: string;
  color: string;
  badge: string;
}

// Unified status display mapping
export const unifiedStatuses: Record<string, StatusMapping> = {
  'draft': {
    display: 'Draft',
    color: 'bg-gray-100 text-gray-800',
    badge: 'Draft'
  },
  'pending': {
    display: 'Pending',
    color: 'bg-blue-100 text-blue-800', 
    badge: 'Pending'
  },
  'approved': {
    display: 'Approved',
    color: 'bg-green-100 text-green-800',
    badge: 'Approved'
  },
  'in_progress': {
    display: 'In Progress',
    color: 'bg-yellow-100 text-yellow-800',
    badge: 'In Progress'
  },
  'completed': {
    display: 'Completed',
    color: 'bg-green-100 text-green-800',
    badge: 'Completed'
  },
  'cancelled': {
    display: 'Cancelled',
    color: 'bg-red-100 text-red-800',
    badge: 'Cancelled'
  }
};

// Map proposal statuses to unified status
export const mapProposalStatus = (proposalStatus: string): string => {
  const mapping: Record<string, string> = {
    'draft': 'draft',
    'sent': 'pending', 
    'viewed': 'pending',
    'approved': 'approved',
    'rejected': 'cancelled'
  };
  return mapping[proposalStatus] || proposalStatus;
};

// Map job statuses to unified status  
export const mapJobStatus = (jobStatus: string): string => {
  const mapping: Record<string, string> = {
    'not_scheduled': 'pending',
    'scheduled': 'approved', 
    'in-progress': 'in_progress',
    'completed': 'completed',
    'cancelled': 'cancelled'
  };
  return mapping[jobStatus] || jobStatus;
};

// Get unified status for job-proposal pair
export const getUnifiedStatus = (jobStatus: string, proposalStatus?: string): StatusMapping => {
  // If there's a proposal, use the most advanced status
  if (proposalStatus) {
    const jobMapped = mapJobStatus(jobStatus);
    const proposalMapped = mapProposalStatus(proposalStatus);
    
    // Status hierarchy (higher number = more advanced)
    const statusHierarchy: Record<string, number> = {
      'draft': 1,
      'pending': 2, 
      'approved': 3,
      'in_progress': 4,
      'completed': 5,
      'cancelled': 0 // Special case - terminal state
    };
    
    // Use the more advanced status
    const jobLevel = statusHierarchy[jobMapped] || 0;
    const proposalLevel = statusHierarchy[proposalMapped] || 0;
    
    const finalStatus = jobLevel > proposalLevel ? jobMapped : proposalMapped;
    return unifiedStatuses[finalStatus] || unifiedStatuses['pending'];
  }
  
  // No proposal, just use job status
  const mappedStatus = mapJobStatus(jobStatus);
  return unifiedStatuses[mappedStatus] || unifiedStatuses['pending'];
};
