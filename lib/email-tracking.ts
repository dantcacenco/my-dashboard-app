import { Resend } from 'resend';
import { createClient } from '@/lib/supabase/server';

const resend = new Resend(process.env.RESEND_API_KEY);

// Track daily email sends
export async function trackEmailSend() {
  const supabase = await createClient();
  const today = new Date().toISOString().split('T')[0];
  
  // Increment daily counter
  const { data: existing } = await supabase
    .from('email_tracking')
    .select('*')
    .eq('date', today)
    .single();
  
  if (existing) {
    const newCount = existing.count + 1;
    
    // Update count
    await supabase
      .from('email_tracking')
      .update({ count: newCount })
      .eq('date', today);
    
    // Check if approaching limit (90 emails)
    if (newCount === 90) {
      await sendLimitWarning(newCount);
    }
    
    return newCount;
  } else {
    // Create new record for today
    await supabase
      .from('email_tracking')
      .insert({ date: today, count: 1 });
    
    return 1;
  }
}

// Send warning email when approaching limit
async function sendLimitWarning(currentCount: number) {
  try {
    await resend.emails.send({
      from: process.env.EMAIL_FROM || 'noreply@fairairhc.service-pro.app',
      to: 'dantcacenco@gmail.com',
      subject: '⚠️ Resend Email Limit Warning - 90 emails sent today',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: #ff6b6b; color: white; padding: 20px; border-radius: 8px 8px 0 0;">
            <h2 style="margin: 0;">⚠️ Email Limit Warning</h2>
          </div>
          <div style="padding: 20px; border: 1px solid #ddd; border-top: none;">
            <p style="font-size: 18px; color: #333;">
              <strong>Current Usage:</strong> ${currentCount} / 100 emails today
            </p>
            <p>You're approaching the daily Resend limit. Only 10 emails remaining!</p>
            
            <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h3 style="margin-top: 0;">Action Required:</h3>
              <ol>
                <li>Go to <a href="https://resend.com/billing">Resend Billing</a></li>
                <li>Upgrade to Pro plan ($20/month)</li>
                <li>Get 5,000 emails/month instead of 3,000</li>
                <li>No daily limits on Pro plan</li>
              </ol>
            </div>
            
            <p style="color: #666;">
              <strong>Note:</strong> Free plan limits are:
              <ul>
                <li>100 emails per day</li>
                <li>3,000 emails per month</li>
              </ul>
            </p>
            
            <a href="https://resend.com/billing" 
               style="display: inline-block; background: #3b82f6; color: white; 
                      padding: 12px 24px; text-decoration: none; border-radius: 6px;">
              Upgrade Now
            </a>
          </div>
        </div>
      `
    });
  } catch (error) {
    console.error('Failed to send limit warning:', error);
  }
}

// Get usage stats
export async function getEmailUsageStats() {
  const supabase = await createClient();
  const today = new Date().toISOString().split('T')[0];
  const firstOfMonth = new Date();
  firstOfMonth.setDate(1);
  
  // Get today's count
  const { data: todayData } = await supabase
    .from('email_tracking')
    .select('count')
    .eq('date', today)
    .single();
  
  // Get month's total
  const { data: monthData } = await supabase
    .from('email_tracking')
    .select('count')
    .gte('date', firstOfMonth.toISOString().split('T')[0]);
  
  const monthTotal = monthData?.reduce((sum, day) => sum + day.count, 0) || 0;
  
  return {
    today: todayData?.count || 0,
    month: monthTotal,
    todayRemaining: 100 - (todayData?.count || 0),
    monthRemaining: 3000 - monthTotal
  };
}