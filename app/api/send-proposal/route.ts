import { NextResponse } from 'next/server'
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request: Request) {
  try {
    const body = await request.json()
    
    const {
      to,
      subject,
      message,
      customer_name,
      proposal_number,
      proposal_url,
      send_copy
    } = body

    if (!to || !subject || !message) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // Create HTML email content with light blue design and rounded corners
    const htmlContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { 
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              line-height: 1.6; 
              color: #333;
              background-color: #f5f5f5;
              margin: 0;
              padding: 0;
            }
            .wrapper {
              background-color: #f5f5f5;
              padding: 40px 20px;
            }
            .container { 
              max-width: 600px; 
              margin: 0 auto; 
              background-color: white;
              border-radius: 12px;
              overflow: hidden;
              box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            }
            .header { 
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white; 
              padding: 30px; 
              text-align: center;
            }
            .header h1 {
              margin: 0;
              font-size: 28px;
              font-weight: 600;
            }
            .header p {
              margin: 5px 0 0 0;
              opacity: 0.95;
              font-size: 16px;
            }
            .content { 
              padding: 30px;
              background-color: white;
            }
            .content h2 {
              color: #333;
              margin-top: 0;
              font-size: 20px;
              font-weight: 600;
            }
            .content p {
              color: #555;
              margin: 15px 0;
              line-height: 1.6;
            }
            .button-container {
              text-align: center;
              margin: 30px 0;
            }
            .button { 
              display: inline-block; 
              padding: 14px 32px; 
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white !important; 
              text-decoration: none; 
              border-radius: 8px; 
              font-weight: 600;
              font-size: 16px;
              box-shadow: 0 4px 6px rgba(102, 126, 234, 0.25);
              transition: transform 0.2s;
            }
            .button:hover {
              transform: translateY(-2px);
              box-shadow: 0 6px 8px rgba(102, 126, 234, 0.35);
            }
            .footer { 
              padding: 20px 30px; 
              text-align: center; 
              color: #888; 
              font-size: 13px;
              background-color: #fafafa;
              border-top: 1px solid #eee;
            }
            .divider {
              height: 1px;
              background-color: #eee;
              margin: 25px 0;
            }
          </style>
        </head>
        <body>
          <div class="wrapper">
            <div class="container">
              <div class="header">
                <h1>Service Pro</h1>
                <p>HVAC Services Proposal</p>
              </div>
              <div class="content">
                <h2>Proposal #${proposal_number}</h2>
                <p>Dear ${customer_name},</p>
                ${message.split('\n').map((line: string) => `<p>${line}</p>`).join('')}
                <div class="divider"></div>
                <div class="button-container">
                  <a href="${proposal_url}" class="button">View Proposal</a>
                </div>
                <div class="divider"></div>
                <p style="text-align: center; color: #888; font-size: 14px;">
                  This link is secure and personalized for you.
                </p>
              </div>
              <div class="footer">
                <p>© 2025 Service Pro. All rights reserved.</p>
                <p>Professional HVAC Services</p>
              </div>
            </div>
          </div>
        </body>
      </html>
    `

    // Send email
    const { data, error } = await resend.emails.send({
      from: 'Service Pro <onboarding@resend.dev>',
      to: [to],
      subject,
      html: htmlContent
    })

    if (error) {
      console.error('Resend error:', error)
      return NextResponse.json(
        { error: 'Failed to send email', details: error },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true, data })
  } catch (error) {
    console.error('Error in send-proposal route:', error)
    return NextResponse.json(
      { error: 'Internal server error', details: error },
      { status: 500 }
    )
  }
}
