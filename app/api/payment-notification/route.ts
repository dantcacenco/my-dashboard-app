import { NextRequest, NextResponse } from 'next/server'
import { Resend } from 'resend'
import { EMAIL_CONFIG, getEmailSender, getBusinessEmail } from '@/lib/config/email'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: NextRequest) {
  try {
    const {
      proposal_id,
      proposal_number,
      customer_name,
      customer_email,
      amount,
      payment_method,
      stripe_session_id
    } = await request.json()

    if (!proposal_id || !proposal_number || !customer_name || !amount) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const paymentMethodDisplay = payment_method === 'ach' ? 'ACH Bank Transfer' : 'Credit/Debit Card'

    // Create email subject
    const subject = `💰 Payment Received - Proposal ${proposal_number} from ${customer_name}`

    // Create HTML email template for business notification
    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>${subject}</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #059669; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9fafb; }
            .status-badge { 
              display: inline-block; 
              padding: 8px 16px; 
              background: #059669; 
              color: white; 
              border-radius: 6px; 
              font-weight: bold;
              margin: 10px 0;
            }
            .details-box { 
              background: white; 
              padding: 15px; 
              border-radius: 6px; 
              margin: 15px 0; 
              border-left: 4px solid #059669;
            }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; }
            .amount { 
              font-size: 24px; 
              font-weight: bold; 
              color: #059669; 
              text-align: center;
              padding: 10px;
              background: #f0fdf4;
              border-radius: 6px;
              margin: 15px 0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>💰 Payment Received!</h1>
              <p>Deposit Payment Confirmation</p>
            </div>
            
            <div class="content">
              <div class="status-badge">
                PAYMENT SUCCESSFUL
              </div>
              
              <div class="amount">
                $${amount.toFixed(2)} RECEIVED
              </div>
              
              <div class="details-box">
                <h3>Payment Details:</h3>
                <p><strong>Proposal Number:</strong> ${proposal_number}</p>
                <p><strong>Customer:</strong> ${customer_name}</p>
                <p><strong>Email:</strong> ${customer_email}</p>
                <p><strong>Amount:</strong> $${amount.toFixed(2)}</p>
                <p><strong>Payment Method:</strong> ${paymentMethodDisplay}</p>
                <p><strong>Payment Date:</strong> ${new Date().toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                })}</p>
                ${stripe_session_id ? `<p><strong>Transaction ID:</strong> ${stripe_session_id.slice(-12)}</p>` : ''}
              </div>

              <div class="details-box" style="border-left-color: #2563eb; background: #eff6ff;">
                <h3>🎯 Next Steps:</h3>
                <ul>
                  <li>Contact customer to schedule project start date</li>
                  <li>Prepare materials and equipment</li>
                  <li>Update project management system</li>
                  <li>Send project timeline to customer</li>
                </ul>
              </div>
            </div>
            
            <div class="footer">
              <p><strong>${EMAIL_CONFIG.company.name}</strong> - Payment Notification</p>
              <p>This is an automated notification from your proposal system</p>
            </div>
          </div>
        </body>
      </html>
    `

    // Send notification email to business
    const emailResult = await resend.emails.send({
      from: getEmailSender(),
      to: [getBusinessEmail()],
      subject: subject,
      html: htmlContent,
      text: `
💰 PAYMENT RECEIVED

Proposal: ${proposal_number}
Customer: ${customer_name} (${customer_email})
Amount: $${amount.toFixed(2)}
Payment Method: ${paymentMethodDisplay}
${stripe_session_id ? `Transaction ID: ${stripe_session_id.slice(-12)}` : ''}

Payment received: ${new Date().toLocaleString()}

Next steps:
- Contact customer to schedule project
- Prepare materials and equipment
- Send project timeline
      `
    })

    return NextResponse.json({ 
      success: true, 
      emailId: emailResult.data?.id 
    })

  } catch (error) {
    console.error('Error sending payment notification:', error)
    return NextResponse.json(
      { error: 'Failed to send notification email' },
      { status: 500 }
    )
  }
}