// Bill.com API Client
// Documentation: https://developer.bill.com/

interface BillComConfig {
  apiKey: string
  devKey: string
  orgId: string
  environment: 'sandbox' | 'production'
}

class BillComClient {
  private config: BillComConfig
  private sessionId: string | null = null
  private baseUrl: string

  constructor(config: BillComConfig) {
    this.config = config
    this.baseUrl = config.environment === 'sandbox' 
      ? 'https://api-sandbox.bill.com/api/v2'
      : 'https://api.bill.com/api/v2'
  }

  // Authenticate and get session
  async authenticate(): Promise<void> {
    try {
      const response = await fetch(`${this.baseUrl}/Login.json`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          devKey: this.config.devKey,
          userName: this.config.apiKey,
          password: this.config.orgId,
        })
      })

      const data = await response.json()
      if (data.response_status === 0) {
        this.sessionId = data.response_data.sessionId
      } else {
        throw new Error(data.response_message || 'Authentication failed')
      }
    } catch (error) {
      console.error('Bill.com authentication error:', error)
      throw error
    }
  }

  // Create an invoice
  async createInvoice(invoiceData: any): Promise<any> {
    if (!this.sessionId) {
      await this.authenticate()
    }

    try {
      const response = await fetch(`${this.baseUrl}/Invoice.json`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          devKey: this.config.devKey,
          sessionId: this.sessionId!,
          data: JSON.stringify({
            vendorId: invoiceData.customerId,
            invoiceNumber: invoiceData.invoiceNumber,
            invoiceDate: invoiceData.date,
            dueDate: invoiceData.dueDate,
            amount: invoiceData.amount,
            description: invoiceData.description,
            lineItems: invoiceData.lineItems
          })
        })
      })

      const data = await response.json()
      if (data.response_status === 0) {
        return data.response_data
      } else {
        throw new Error(data.response_message || 'Failed to create invoice')
      }
    } catch (error) {
      console.error('Bill.com invoice creation error:', error)
      throw error
    }
  }

  // Send invoice for payment
  async sendInvoice(invoiceId: string, customerEmail: string): Promise<any> {
    if (!this.sessionId) {
      await this.authenticate()
    }

    try {
      const response = await fetch(`${this.baseUrl}/SendInvoice.json`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          devKey: this.config.devKey,
          sessionId: this.sessionId!,
          invoiceId: invoiceId,
          email: customerEmail
        })
      })

      const data = await response.json()
      if (data.response_status === 0) {
        return data.response_data
      } else {
        throw new Error(data.response_message || 'Failed to send invoice')
      }
    } catch (error) {
      console.error('Bill.com send invoice error:', error)
      throw error
    }
  }

  // Get payment URL for customer
  async getPaymentUrl(invoiceId: string): Promise<string> {
    // Bill.com generates a unique payment URL for each invoice
    // This would be returned from the sendInvoice response
    return `https://app.bill.com/pay/${invoiceId}`
  }
}

// Export singleton instance
let billcomClient: BillComClient | null = null

export function getBillComClient(): BillComClient {
  if (!billcomClient) {
    // Only initialize if credentials are available
    if (process.env.BILLCOM_API_KEY && process.env.BILLCOM_DEV_KEY && process.env.BILLCOM_ORG_ID) {
      billcomClient = new BillComClient({
        apiKey: process.env.BILLCOM_API_KEY,
        devKey: process.env.BILLCOM_DEV_KEY,
        orgId: process.env.BILLCOM_ORG_ID,
        environment: process.env.NODE_ENV === 'production' ? 'production' : 'sandbox'
      })
    } else {
      // Return a mock client if credentials not available
      throw new Error('Bill.com credentials not configured')
    }
  }
  return billcomClient
}

// Feature flag to switch between Stripe and Bill.com
export function shouldUseBillCom(): boolean {
  // Default to false until Bill.com is configured
  return process.env.USE_BILLCOM === 'true' && 
         !!process.env.BILLCOM_API_KEY && 
         !!process.env.BILLCOM_DEV_KEY && 
         !!process.env.BILLCOM_ORG_ID
}
