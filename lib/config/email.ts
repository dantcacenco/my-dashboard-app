// Email configuration
export const EMAIL_CONFIG = {
  from: {
    name: 'Service Pro',
    email: process.env.EMAIL_FROM || 'onboarding@resend.dev'
  },
  
  business: {
    email: process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com',
    name: 'Service Pro Team'
  },
  
  company: {
    name: 'Service Pro HVAC',
    tagline: 'Professional HVAC Services',
    phone: '(555) 123-4567',
    email: 'info@servicepro.com',
    website: 'https://servicepro-hvac.vercel.app'
  }
}

export const getEmailSender = () => {
  return `${EMAIL_CONFIG.from.name} <${EMAIL_CONFIG.from.email}>`
}

export const getBusinessEmail = () => {
  return EMAIL_CONFIG.business.email
}
