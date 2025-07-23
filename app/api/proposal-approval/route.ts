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
      total_amount,
      customer_notes,
      action_type, // 'approved' or 'rejected'
      proposal_title
    } = await request.json()

    if (!proposal_id || !proposal_number || !customer_name || !action_type) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const isApproved = action_type === 'approved'
    const actionEmoji = isApproved ? '✅' : '❌'
    const actionText = isApproved ? 'APPROVED' : 'DECLINED'
    const actionColor = isApproved ? '#059669' : '#dc2626'

    // Create email subject
    const subject = isApproved 
      ? EMAIL_CONFIG.subjects.approvalToBusinesss(proposal_number, customer_name)
      : EMAIL_CONFIG.subjects.rejectionToBusiness(proposal_number, customer_name)

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
            .header { background: ${actionColor}; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9fafb; }
            .status-badge { 
              display: inline-block; 
              padding: 8px 16px; 
              background: ${actionColor}; 
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
              border-left: 4px solid ${actionColor};
            }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; }
            .customer-notes { 
              background: #f3f4f6; 
              padding: 12px; 
              border-radius: 6px; 
              font-style: italic;
              margin: 10px 0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>${actionEmoji} Proposal ${actionText}</h1>
              <p>Customer Response Received</p>
            </div>
            
            <div class="content">
              <div class="status-badge">
                ${actionText}
              </div>
              
              <div class="details-box">
                <h3>Proposal Details:</h3>
                <p><strong>Proposal Number:</strong> ${proposal_number}</p>
                <p><strong>Project:</strong> ${proposal_title || 'N/A'}</p>
                <p><strong>Customer:</strong> ${customer_name}</p>
                <p><strong>Email:</strong> ${customer_email}</p>
                ${total_amount ? `<p><strong>Total Amount:</strong> $${total_amount.toFixed(2)}</p>` : ''}
                <p><strong>Action Date:</strong> ${new Date().toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                })}</p>
              </div>

              ${customer_notes ? `
                <div class="details-box">
                  <h3>Customer Notes:</h3>
                  <div class="customer-notes">
                    "${customer_notes}"
                  </div>
                </div>
              ` : ''}

              ${isApproved ? `
                <div class="details-box" style="border-left-color: #059669; background: #f0fdf4;">
                  <h3>🎉 Next Steps:</h3>
                  <ul>
                    <li>Contact customer to schedule work</li>
                    <li>Prepare materials and equipment</li>
                    <li>Send contract for signature</li>
                    <li>Collect deposit payment</li>
                  </ul>
                </div>
              ` : `
                <div class="details-box" style="border-left-color: #dc2626; background: #fef2f2;">
                  <h3>📝 Follow-up Actions:</h3>
                  <ul>
                    <li>Review customer feedback</li>
                    <li>Consider reaching out to discuss alternatives</li>
                    <li>Update proposal if needed</li>
                    <li>Follow up in a few weeks</li>
                  </ul>
                </div>
              `}
            </div>
            
            <div class="footer">
              <p><strong>${EMAIL_CONFIG.company.name}</strong> - Business Notification</p>
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
${actionEmoji} PROPOSAL ${actionText}

Proposal: ${proposal_number}
Customer: ${customer_name} (${customer_email})
${proposal_title ? `Project: ${proposal_title}` : ''}
${total_amount ? `Amount: $${total_amount.toFixed(2)}` : ''}

${customer_notes ? `Customer Notes: "${customer_notes}"` : ''}

Action taken: ${new Date().toLocaleString()}
      `
    })

    return NextResponse.json({ 
      success: true, 
      emailId: emailResult.data?.id 
    })

  } catch (error) {
    console.error('Error sending approval notification:', error)
    return NextResponse.json(
      { error: 'Failed to send notification email' },
      { status: 500 }
    )
  }
}