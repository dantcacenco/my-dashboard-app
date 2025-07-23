// Email configuration - centralized settings
export const EMAIL_CONFIG = {
  // Sender information
  from: {
    name: 'Service Pro',
    email: process.env.EMAIL_FROM || 'onboarding@resend.dev'
  },
  
  // Business email for receiving notifications
  business: {
    email: process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com',
    name: 'Service Pro Team'
  },
  
  // Company information
  company: {
    name: 'Service Pro',
    tagline: 'Professional HVAC Services',
    phone: '(555) 123-4567',
    email: 'info@servicepro.com',
    website: 'https://servicepro.com'
  },
  
  // Email templates
  subjects: {
    proposalToCustomer: (proposalNumber: string) => `Proposal ${proposalNumber} from Service Pro`,
    approvalToBusinesss: (proposalNumber: string, customerName: string) => 
      `✅ Proposal ${proposalNumber} APPROVED by ${customerName}`,
    rejectionToBusiness: (proposalNumber: string, customerName: string) => 
      `❌ Proposal ${proposalNumber} DECLINED by ${customerName}`,
    viewedNotification: (proposalNumber: string, customerName: string) => 
      `👀 Proposal ${proposalNumber} viewed by ${customerName}`
  }
}

// Helper function to get formatted sender
export const getEmailSender = () => {
  return `${EMAIL_CONFIG.from.name} <${EMAIL_CONFIG.from.email}>`
}

// Helper function to get business recipient
export const getBusinessEmail = () => {
  return EMAIL_CONFIG.business.email
}