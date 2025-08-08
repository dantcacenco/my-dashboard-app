import { NextRequest, NextResponse } from 'next/server'
import { Resend } from 'resend'
import { createClient } from '@/lib/supabase/server'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    console.log('Received request body:', body)
    
    const {
      proposalId,  // This is the proposal ID
      to,
      subject,
      message,
      customer_name,
      proposal_number,
      proposal_url,
      send_copy
    } = body

    // Validate required fields
    if (!proposalId) {
      console.error('Missing proposalId in request')
      return NextResponse.json(
        { error: 'Missing proposal ID' },
        { status: 400 }
      )
    }

    if (!to || !subject || !message) {
      console.error('Missing required email fields')
      return NextResponse.json(
        { error: 'Missing required email fields' },
        { status: 400 }
      )
    }

    // Update proposal status first
    const supabase = await createClient()
    const { error: updateError } = await supabase
      .from('proposals')
      .update({ 
        status: 'sent',
        sent_at: new Date().toISOString()
      })
      .eq('id', proposalId)

    if (updateError) {
      console.error('Error updating proposal:', updateError)
    }

    // Get sender email config
    const fromEmail = process.env.EMAIL_FROM || 'onboarding@resend.dev'
    const businessEmail = process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com'

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
            .header { background: #2563eb; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { padding: 20px; background: #f9fafb; border: 1px solid #e5e7eb; }
            .button { 
              display: inline-block; 
              padding: 12px 24px; 
              background: #2563eb; 
              color: white !important; 
              text-decoration: none; 
              border-radius: 6px; 
              margin: 20px 0; 
            }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; background: #f3f4f6; border-radius: 0 0 8px 8px; }
            .proposal-details { 
              background: white; 
              padding: 15px; 
              border-radius: 6px; 
              margin: 15px 0; 
              border: 1px solid #e5e7eb;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Service Pro HVAC</h1>
              <p>Professional HVAC Services</p>
            </div>
            
            <div class="content">
              <h2>Your Proposal is Ready for Review</h2>
              
              <div class="proposal-details">
                <h3>Proposal Details:</h3>
                <p><strong>Proposal Number:</strong> ${proposal_number}</p>
                <p><strong>Customer:</strong> ${customer_name}</p>
              </div>
              
              <div style="white-space: pre-line; margin: 20px 0;">
                ${message.replace(/\n/g, '<br>')}
              </div>
              
              <div style="text-align: center; margin: 30px 0;">
                <a href="${proposal_url}" class="button" style="color: white !important;">
                  View & Approve Proposal
                </a>
              </div>
              
              <p style="font-size: 14px; color: #666; text-align: center;">
                This link is secure and personalized for you.
              </p>
            </div>
            
            <div class="footer">
              <p><strong>Service Pro HVAC</strong></p>
              <p>Phone: (555) 123-4567 | Email: info@servicepro.com</p>
              <p>Professional HVAC Services</p>
            </div>
          </div>
        </body>
      </html>
    `

    // Send email to customer
    console.log('Sending email to:', to)
    const emailResult = await resend.emails.send({
      from: `Service Pro <${fromEmail}>`,
      to: [to],
      subject: subject,
      html: htmlContent,
      text: message + `\n\nView your proposal: ${proposal_url}`
    })

    console.log('Email sent successfully:', emailResult)

    // Send copy to business email if requested
    if (send_copy) {
      console.log('Sending copy to business:', businessEmail)
      await resend.emails.send({
        from: `Service Pro <${fromEmail}>`,
        to: [businessEmail],
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
      emailId: emailResult.data?.id,
      message: 'Email sent successfully'
    })

  } catch (error: any) {
    console.error('Error in send-proposal API:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to send email' },
      { status: 500 }
    )
  }
}
