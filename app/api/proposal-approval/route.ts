import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: NextRequest) {
  try {
    const { proposalId, approved, customerNotes, customerName } = await request.json()

    if (!proposalId) {
      return NextResponse.json(
        { error: 'Proposal ID is required' },
        { status: 400 }
      )
    }

    const supabase = await createClient()
    const now = new Date().toISOString()

    // Get proposal details for email
    const { data: proposalData } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (name, email, phone)
      `)
      .eq('id', proposalId)
      .single()

    const updateData: any = {
      status: approved ? 'approved' : 'rejected',
      customer_notes: customerNotes || null
    }

    if (approved) {
      updateData.approved_at = now
    } else {
      updateData.rejected_at = now
    }

    // Update proposal
    const { data: proposal, error } = await supabase
      .from('proposals')
      .update(updateData)
      .eq('id', proposalId)
      .select(`
        *,
        customers (id, name, email, phone)
      `)
      .single()

    if (error) {
      console.error('Error updating proposal:', error)
      return NextResponse.json(
        { error: 'Failed to update proposal' },
        { status: 500 }
      )
    }

    // Send notification email to business
    if (approved && proposalData) {
      const businessEmail = process.env.BUSINESS_EMAIL || 'dantcacenco@gmail.com'
      const fromEmail = process.env.EMAIL_FROM || 'onboarding@resend.dev'
      
      const emailHtml = `
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
                <h1>🎉 Proposal Approved!</h1>
              </div>
              <div class="content">
                <h2>Great news! Proposal #${proposalData.proposal_number} has been approved</h2>
                
                <div class="details">
                  <h3>Customer Details:</h3>
                  <p><strong>Name:</strong> ${proposalData.customers.name}</p>
                  <p><strong>Email:</strong> ${proposalData.customers.email}</p>
                  <p><strong>Phone:</strong> ${proposalData.customers.phone}</p>
                  <p><strong>Approved by:</strong> ${customerName || proposalData.customers.name}</p>
                  <p><strong>Total Amount:</strong> $${proposalData.total.toFixed(2)}</p>
                  ${customerNotes ? `<p><strong>Customer Notes:</strong> ${customerNotes}</p>` : ''}
                </div>
                
                <div class="details">
                  <h3>Next Steps:</h3>
                  <ul>
                    <li>Customer will be prompted to pay 50% deposit ($${(proposalData.total * 0.5).toFixed(2)})</li>
                    <li>Contact customer to schedule project start</li>
                    <li>Prepare materials and equipment</li>
                  </ul>
                </div>
                
                <p><strong>Time:</strong> ${new Date().toLocaleString()}</p>
              </div>
              <div class="footer">
                <p>This is an automated notification from Service Pro</p>
              </div>
            </div>
          </body>
        </html>
      `

      try {
        await resend.emails.send({
          from: `Service Pro <${fromEmail}>`,
          to: [businessEmail],
          subject: `✅ Proposal #${proposalData.proposal_number} APPROVED by ${proposalData.customers.name}`,
          html: emailHtml,
          text: `Proposal #${proposalData.proposal_number} has been approved by ${proposalData.customers.name}. Total: $${proposalData.total.toFixed(2)}`
        })
      } catch (emailError) {
        console.error('Error sending approval email:', emailError)
        // Don't fail the approval if email fails
      }
    }

    return NextResponse.json({ 
      success: true,
      proposal 
    })

  } catch (error: any) {
    console.error('Error in proposal approval:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to process approval' },
      { status: 500 }
    )
  }
}
