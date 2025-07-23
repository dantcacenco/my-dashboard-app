import { NextRequest, NextResponse } from 'next/server'
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: NextRequest) {
  try {
    const {
      to,
      subject,
      message,
      customer_name,
      proposal_number,
      proposal_url,
      send_copy
    } = await request.json()

    if (!to || !subject || !message) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Create HTML email template
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
            .header { background: #2563eb; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9fafb; }
            .button { 
              display: inline-block; 
              padding: 12px 24px; 
              background: #2563eb; 
              color: white; 
              text-decoration: none; 
              border-radius: 6px; 
              margin: 20px 0; 
            }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; }
            .proposal-details { 
              background: white; 
              padding: 15px; 
              border-radius: 6px; 
              margin: 15px 0; 
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Service Pro</h1>
              <p>Professional HVAC Services</p>
            </div>
            
            <div class="content">
              <h2>New Proposal Ready for Review</h2>
              
              <div class="proposal-details">
                <h3>Proposal Details:</h3>
                <p><strong>Proposal Number:</strong> ${proposal_number}</p>
                <p><strong>Customer:</strong> ${customer_name}</p>
              </div>
              
              <div style="white-space: pre-line; margin: 20px 0;">
                ${message}
              </div>
              
              <div style="text-align: center;">
                <a href="${proposal_url}" class="button">
                  View & Approve Proposal
                </a>
              </div>
              
              <p style="font-size: 14px; color: #666;">
                This link is secure and personalized for you. It will expire in 30 days.
              </p>
            </div>
            
            <div class="footer">
              <p><strong>Service Pro</strong></p>
              <p>Phone: (555) 123-4567 | Email: info@servicepro.com</p>
              <p>Professional HVAC Installation, Repair & Maintenance</p>
            </div>
          </div>
        </body>
      </html>
    `

    // Send email to customer
    const emailResult = await resend.emails.send({
      from: 'Service Pro <proposals@servicepro.com>',
      to: [to],
      subject: subject,
      html: htmlContent,
      text: message + `\n\nView your proposal: ${proposal_url}`
    })

    // Send copy to sender if requested
    if (send_copy) {
      await resend.emails.send({
        from: 'Service Pro <proposals@servicepro.com>',
        to: ['info@servicepro.com'], // Replace with your business email
        subject: `[COPY] ${subject}`,
        html: `
          <div style="background: #fef3c7; padding: 10px; margin-bottom: 20px; border-radius: 4px;">
            <strong>This is a copy of the proposal sent to ${customer_name} (${to})</strong>
          </div>
          ${htmlContent}
        `,
        text: `[COPY] Sent to ${customer_name} (${to})\n\n${message}\n\nView proposal: ${proposal_url}`
      })
    }

    return NextResponse.json({ 
      success: true, 
      emailId: emailResult.data?.id 
    })

  } catch (error) {
    console.error('Error sending email:', error)
    return NextResponse.json(
      { error: 'Failed to send email' },
      { status: 500 }
    )
  }
}