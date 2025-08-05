import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const {
      proposalId,
      proposalNumber,
      customerName,
      customerEmail,
      message,
      total,
      viewLink
    } = await request.json()

    // Log the email details (Resend can be added later)
    console.log('Sending proposal email:', {
      to: customerEmail,
      proposalNumber,
      viewLink,
      total
    })

    // Format currency correctly (total is already in dollars)
    const formattedTotal = new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(total)

    // If RESEND_API_KEY exists, send actual email
    if (process.env.RESEND_API_KEY) {
      try {
        // Dynamic import to avoid build errors if resend isn't installed
        const { Resend } = await import('resend')
        const resend = new Resend(process.env.RESEND_API_KEY)
        
        const { error } = await resend.emails.send({
          from: 'Service Pro <noreply@servicepro.com>',
          to: customerEmail,
          subject: `Proposal #${proposalNumber} from Service Pro`,
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2>Proposal #${proposalNumber}</h2>
              <p>Hi ${customerName},</p>
              <p>${message.replace(/\n/g, '<br>')}</p>
              <p style="margin: 30px 0;">
                <a href="${viewLink}" style="background-color: #3b82f6; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
                  View Proposal
                </a>
              </p>
              <p><strong>Total: ${formattedTotal}</strong></p>
              <hr style="margin: 30px 0; border: none; border-top: 1px solid #e5e7eb;">
              <p style="color: #6b7280; font-size: 14px;">
                This proposal was sent from Service Pro. If you have any questions, please contact us.
              </p>
            </div>
          `
        })

        if (error) {
          console.error('Resend error:', error)
          // Don't fail - still mark as sent
        }
      } catch (importError) {
        console.log('Resend not installed, skipping email send')
      }
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error in send-proposal API:', error)
    return NextResponse.json(
      { error: 'Failed to send proposal' },
      { status: 500 }
    )
  }
}
