import { NextRequest, NextResponse } from 'next/server'
import { Resend } from 'resend'

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
      payment_stage,
      stripe_session_id
    } = await request.json()

    const businessEmail = process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com'
    const fromEmail = process.env.EMAIL_FROM || 'onboarding@resend.dev'

    const stageLabel = payment_stage === 'roughin' ? 'Rough In' : 
                      payment_stage.charAt(0).toUpperCase() + payment_stage.slice(1)

    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #10b981; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { padding: 20px; background: #f9fafb; border: 1px solid #e5e7eb; }
            .details { background: white; padding: 15px; border-radius: 6px; margin: 15px 0; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>💰 Payment Received!</h1>
            </div>
            <div class="content">
              <h2>${stageLabel} Payment Received for Proposal #${proposal_number}</h2>
              
              <div class="details">
                <h3>Payment Details:</h3>
                <p><strong>Customer:</strong> ${customer_name}</p>
                <p><strong>Email:</strong> ${customer_email}</p>
                <p><strong>Amount:</strong> $${amount.toFixed(2)}</p>
                <p><strong>Payment Stage:</strong> ${stageLabel}</p>
                <p><strong>Payment Method:</strong> ${payment_method}</p>
                <p><strong>Transaction ID:</strong> ${stripe_session_id?.slice(-12) || 'N/A'}</p>
                <p><strong>Time:</strong> ${new Date().toLocaleString()}</p>
              </div>
              
              <div class="details">
                <h3>Next Steps:</h3>
                <ul>
                  ${payment_stage === 'deposit' ? '<li>Schedule project start</li><li>Order materials</li>' : ''}
                  ${payment_stage === 'roughin' ? '<li>Complete rough-in work</li><li>Schedule final inspection</li>' : ''}
                  ${payment_stage === 'final' ? '<li>Project complete!</li><li>Schedule follow-up</li>' : ''}
                </ul>
              </div>
            </div>
            <div class="footer">
              <p>This is an automated notification from Service Pro</p>
            </div>
          </div>
        </body>
      </html>
    `

    await resend.emails.send({
      from: `Service Pro <${fromEmail}>`,
      to: [businessEmail],
      subject: `💰 Payment Received - ${stageLabel} for Proposal #${proposal_number}`,
      html: htmlContent,
      text: `Payment received for ${stageLabel} - Proposal #${proposal_number}\nCustomer: ${customer_name}\nAmount: $${amount.toFixed(2)}`
    })

    return NextResponse.json({ success: true })

  } catch (error: any) {
    console.error('Error sending payment notification:', error)
    return NextResponse.json(
      { error: 'Failed to send notification' },
      { status: 500 }
    )
  }
}
