// Test Resend Email with service-pro.app domain
// Usage: npx tsx test-email.ts

import { Resend } from 'resend';

const resend = new Resend('re_hR5Qg7qC_7K3XcjzyGMztvaavZoGUoc6m');

async function testEmail() {
  console.log('🚀 Testing email configuration for Fair Air HC...\n');
  
  try {
    const { data, error } = await resend.emails.send({
      from: 'noreply@fairairhc.service-pro.app', // Automated sender - MUST match verified domain
      replyTo: 'dantcacenco@gmail.com', // Where replies go (testing)
      // replyTo: 'fairairhc@gmail.com', // Production reply-to
      to: 'dantcacenco@gmail.com', // UPDATE THIS with your test email
      subject: 'Test Email from Fair Air HC Service Pro',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Fair Air HC - Email Configuration Test</h2>
          <p>This email confirms your setup is working correctly:</p>
          <ul style="line-height: 1.8;">
            <li>✅ Domain verified: <strong>fairairhc.service-pro.app</strong></li>
            <li>✅ From address: <strong>noreply@fairairhc.service-pro.app</strong></li>
            <li>✅ Reply-to: <strong>dantcacenco@gmail.com</strong> (testing)</li>
            <li>✅ App URL: <strong>https://fairairhc.service-pro.app</strong></li>
          </ul>
          <p style="margin-top: 20px;">
            <strong>Test Reply:</strong> Hit reply to this email - it should go to dantcacenco@gmail.com
          </p>
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
          <p style="color: #666; font-size: 14px;">
            For production, update reply-to to fairairhc@gmail.com
          </p>
        </div>
      `
    });

    if (error) {
      console.error('❌ Error:', error);
      console.log('\nTroubleshooting:');
      console.log('1. Make sure service-pro.app is verified in Resend');
      console.log('2. Check DNS records are properly configured');
      console.log('3. Verification can take 5-30 minutes');
    } else {
      console.log('✅ Email sent successfully!');
      console.log('📧 Email ID:', data?.id);
      console.log('\n📬 Check your inbox at dantcacenco@gmail.com');
      console.log('💡 Try replying to test the reply-to address');
    }
  } catch (err) {
    console.error('❌ Failed:', err);
  }
}

testEmail();
