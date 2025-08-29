// Shared email templates for consistent branding
export const emailStyles = {
  container: `
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    max-width: 600px;
    margin: 0 auto;
    background-color: #ffffff;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  `,
  header: `
    background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
    color: white;
    padding: 32px 24px;
    text-align: center;
  `,
  logo: `
    font-size: 24px;
    font-weight: bold;
    margin-bottom: 8px;
  `,
  tagline: `
    font-size: 14px;
    opacity: 0.9;
  `,
  body: `
    padding: 32px 24px;
    color: #333333;
    line-height: 1.6;
  `,
  button: `
    display: inline-block;
    background: linear-gradient(135deg, #fb923c 0%, #f97316 100%);
    color: white;
    padding: 14px 32px;
    text-decoration: none;
    border-radius: 8px;
    font-weight: 600;
    font-size: 16px;
    margin: 24px 0;
    box-shadow: 0 4px 6px rgba(251, 146, 60, 0.3);
  `,
  footer: `
    padding: 24px;
    text-align: center;
    color: #666666;
    font-size: 14px;
    border-top: 1px solid #e5e7eb;
  `,
  infoBox: `
    background-color: #f3f4f6;
    border-left: 4px solid #3b82f6;
    padding: 16px;
    margin: 20px 0;
    border-radius: 4px;
  `
}

export function getProposalEmailTemplate({
  customerName,
  proposalNumber,
  message,
  proposalUrl,
  companyName = 'Fair Air HC'
}: {
  customerName: string
  proposalNumber: string
  message?: string
  proposalUrl: string
  companyName?: string
}) {
  return `
    <div style="${emailStyles.container}">
      <div style="${emailStyles.header}">
        <div style="${emailStyles.logo}">${companyName}</div>
        <div style="${emailStyles.tagline}">Professional HVAC Services</div>
      </div>
      
      <div style="${emailStyles.body}">
        <h2 style="color: #1f2937; margin-top: 0;">Your Proposal is Ready!</h2>
        
        <p>Hi ${customerName || 'Customer'},</p>
        
        <div style="white-space: pre-wrap; margin: 20px 0;">
          ${message || `We're pleased to present you with Proposal #${proposalNumber} for your HVAC service needs.
          
Please review the attached proposal and let us know if you have any questions.`}
        </div>
        
        <div style="text-align: center;">
          <a href="${proposalUrl}" style="${emailStyles.button}">
            View Proposal
          </a>
        </div>
        
        <p style="color: #6b7280; font-size: 14px;">
          If the button doesn't work, copy and paste this link:<br>
          <a href="${proposalUrl}" style="color: #3b82f6; word-break: break-all;">
            ${proposalUrl}
          </a>
        </p>
      </div>
      
      <div style="${emailStyles.footer}">
        <p style="margin: 0;">Best regards,</p>
        <p style="margin: 4px 0; font-weight: 600;">${companyName}</p>
        <p style="margin: 8px 0 0 0; font-size: 12px; color: #9ca3af;">
          This is an automated message from Service Pro
        </p>
      </div>
    </div>
  `
}

export function getApprovalEmailTemplate({
  proposalNumber,
  customerName,
  customerEmail,
  customerPhone,
  totalAmount,
  approvedBy,
  proposalUrl,
  companyName = 'Fair Air HC'
}: {
  proposalNumber: string
  customerName: string
  customerEmail: string
  customerPhone?: string
  totalAmount: string
  approvedBy: string
  proposalUrl: string
  companyName?: string
}) {
  return `
    <div style="${emailStyles.container}">
      <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); ${emailStyles.header.replace('background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);', '')}">
        <div style="${emailStyles.logo}">🎉 Proposal Approved!</div>
        <div style="${emailStyles.tagline}">Great news! Proposal #${proposalNumber} has been approved</div>
      </div>
      
      <div style="${emailStyles.body}">
        <h2 style="color: #1f2937; margin-top: 0;">Customer Has Approved the Proposal</h2>
        
        <div style="${emailStyles.infoBox}">
          <h3 style="margin-top: 0; color: #1f2937;">Customer Details:</h3>
          <p style="margin: 8px 0;"><strong>Name:</strong> ${customerName}</p>
          <p style="margin: 8px 0;"><strong>Email:</strong> ${customerEmail}</p>
          ${customerPhone ? `<p style="margin: 8px 0;"><strong>Phone:</strong> ${customerPhone}</p>` : ''}
          <p style="margin: 8px 0;"><strong>Approved by:</strong> ${approvedBy}</p>
          <p style="margin: 8px 0;"><strong>Total Amount:</strong> ${totalAmount}</p>
        </div>
        
        <div style="${emailStyles.infoBox}; border-left-color: #10b981;">
          <h3 style="margin-top: 0; color: #1f2937;">Next Steps:</h3>
          <ul style="margin: 8px 0; padding-left: 20px;">
            <li>Customer will be prompted to pay 50% deposit (${(parseFloat(totalAmount.replace(/[^0-9.-]+/g, '')) * 0.5).toFixed(2)})</li>
            <li>Contact customer to schedule project start</li>
            <li>Prepare materials and equipment</li>
          </ul>
        </div>
        
        <div style="text-align: center;">
          <a href="${proposalUrl}" style="${emailStyles.button}">
            View Proposal
          </a>
        </div>
        
        <p style="color: #6b7280; font-size: 14px;">
          Time: ${new Date().toLocaleString()}
        </p>
      </div>
      
      <div style="${emailStyles.footer}">
        <p style="margin: 0;">This is an automated notification from Service Pro</p>
        <p style="margin: 4px 0; font-weight: 600;">${companyName}</p>
      </div>
    </div>
  `
}

export function getCopyEmailTemplate({
  proposalNumber,
  customerName,
  customerEmail,
  message,
  proposalUrl,
  companyName = 'Fair Air HC'
}: {
  proposalNumber: string
  customerName: string
  customerEmail: string
  message?: string
  proposalUrl: string
  companyName?: string
}) {
  return `
    <div style="${emailStyles.container}">
      <div style="${emailStyles.header}">
        <div style="${emailStyles.logo}">[COPY] Proposal Sent</div>
        <div style="${emailStyles.tagline}">Proposal #${proposalNumber} sent to ${customerEmail}</div>
      </div>
      
      <div style="${emailStyles.body}">
        <h2 style="color: #1f2937; margin-top: 0;">Proposal Successfully Sent</h2>
        
        <div style="${emailStyles.infoBox}">
          <p style="margin: 8px 0;"><strong>To:</strong> ${customerName} (${customerEmail})</p>
          <p style="margin: 8px 0;"><strong>Proposal #:</strong> ${proposalNumber}</p>
          <p style="margin: 8px 0;"><strong>Sent at:</strong> ${new Date().toLocaleString()}</p>
        </div>
        
        ${message ? `
        <div style="${emailStyles.infoBox}">
          <p style="margin: 8px 0;"><strong>Message included:</strong></p>
          <p style="margin: 8px 0; white-space: pre-wrap;">${message}</p>
        </div>
        ` : ''}
        
        <div style="text-align: center;">
          <a href="${proposalUrl}" style="${emailStyles.button}">
            View Proposal
          </a>
        </div>
        
        <p style="color: #6b7280; font-size: 14px;">
          This is a copy of the proposal sent to the customer for your records.
        </p>
      </div>
      
      <div style="${emailStyles.footer}">
        <p style="margin: 0;">Internal notification from Service Pro</p>
        <p style="margin: 4px 0; font-weight: 600;">${companyName}</p>
      </div>
    </div>
  `
}