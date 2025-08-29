# Status Management & Payment Reminder Strategy

## Version 2.2 STABLE - Status & Notification System

### Problem Statement
The current status system conflates operational work status with payment status, creating confusion when:
- Work is in progress while payments are being collected
- Job is physically complete but payments are outstanding
- Technicians need to update work status without affecting payment tracking

### Proposed Solution: Dual Status System

## 1. Separate Status Tracking

### Job Work Status (Technician-controlled)
```
- not_scheduled
- scheduled
- work_started
- in_progress
- rough_in_complete
- work_complete
- cancelled
```

### Payment Status (System-controlled)
```
- pending
- deposit_paid (50%)
- rough_in_paid (30%)
- final_paid (20%)
- paid_in_full
```

### Display Logic
- **Technician View:** Shows work status primarily
- **Admin View:** Shows both statuses (Work: In Progress | Payment: Deposit Paid)
- **Customer View:** Shows simplified combined status

## 2. Automated Payment Reminder System

### Trigger: Job Marked "work_complete"

#### Immediate Actions (Day 0)
```javascript
// When technician marks job as complete
async function onJobComplete(jobId) {
  // 1. Update job status
  await updateJobStatus(jobId, 'work_complete')
  
  // 2. Send completion notification to customer
  await sendEmail({
    to: customer.email,
    template: 'job_complete_payment_reminder',
    data: {
      remainingBalance: calculateRemainingBalance(),
      paymentLink: generatePaymentLink()
    }
  })
  
  // 3. Schedule follow-up reminders
  await scheduleReminders(jobId)
}
```

#### Reminder Schedule

**Day 2 - First Reminder**
- **To:** Customer
- **Subject:** "Payment Reminder: Your HVAC Service is Complete"
- **Content:** Friendly reminder with payment link
- **Action:** Log reminder sent

**Day 7 - Second Reminder + Admin Alert**
- **To Customer:**
  - Subject: "Second Notice: Payment Due for HVAC Service"
  - Content: Firmer tone, mention late fee possibility
- **To Admin:**
  - Subject: "ACTION REQUIRED: Customer Payment Overdue"
  - Content: Customer details, amount due, days overdue
  - Action items: Call customer, review account

**Weekly Reminders (Day 14, 21, 28...)**
- **To Customer:** Escalating urgency
- **To Admin:** Dashboard alert, email summary
- **System:** Flag account as "Collections Risk"

### Database Schema Updates

```sql
-- Add to jobs table
ALTER TABLE jobs ADD COLUMN work_status VARCHAR(50);
ALTER TABLE jobs ADD COLUMN work_completed_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN payment_status VARCHAR(50);

-- New table for reminder tracking
CREATE TABLE payment_reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id UUID REFERENCES jobs(id),
  reminder_type VARCHAR(50), -- 'day_2', 'day_7', 'weekly'
  sent_at TIMESTAMP DEFAULT NOW(),
  response_status VARCHAR(50), -- 'pending', 'viewed', 'paid'
  created_at TIMESTAMP DEFAULT NOW()
);

-- Scheduled jobs for reminders
CREATE TABLE reminder_schedule (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id UUID REFERENCES jobs(id),
  scheduled_for TIMESTAMP,
  reminder_type VARCHAR(50),
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'sent', 'cancelled'
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 3. Implementation Plan

### Phase 1: Status Separation
1. Add `work_status` field to jobs table
2. Update technician UI to use work_status
3. Keep existing status for payment tracking
4. Update display logic to show both

### Phase 2: Email Templates
Create templates for:
- Job completion notification
- Payment reminder (day 2)
- Urgent payment reminder (day 7)
- Weekly payment reminder
- Admin alert templates

### Phase 3: Automation Setup
1. Implement Supabase Edge Functions for scheduling
2. Create cron jobs for reminder processing
3. Add reminder tracking dashboard

### Phase 4: Admin Dashboard Updates
- Add "Overdue Payments" widget
- Show aging report (30, 60, 90 days)
- Quick actions: Send reminder, Call customer, Add note

## 4. Email Template Examples

### Job Completion Email
```
Subject: Your HVAC Service is Complete! 

Hi [Customer Name],

Great news! Your HVAC service at [Address] has been completed by our technician.

Service Summary:
- Job #: [Job Number]
- Services Performed: [Service List]
- Remaining Balance: [Amount]

[PAY NOW BUTTON]

Thank you for choosing Service Pro!
```

### Day 7 Reminder (Customer)
```
Subject: Second Notice: Payment Due for HVAC Service

Hi [Customer Name],

This is a reminder that payment for your recent HVAC service is now overdue.

Details:
- Job #: [Job Number]
- Completed: [Date]
- Amount Due: [Amount]
- Days Overdue: 7

Please make payment immediately to avoid late fees.

[PAY NOW BUTTON]

Questions? Reply to this email or call us at [Phone].
```

### Day 7 Alert (Admin)
```
Subject: ACTION REQUIRED: Payment Overdue - [Customer Name]

Customer: [Customer Name]
Job #: [Job Number]
Amount Due: [Amount]
Days Overdue: 7
Phone: [Customer Phone]

Action Items:
□ Call customer
□ Send manual follow-up
□ Review payment history
□ Add collection note

[VIEW CUSTOMER] [VIEW JOB]
```

## 5. Status Update Rules

### Technician Can Update:
- `work_status` field only
- Cannot modify payment status
- Can add notes about work progress

### System Auto-Updates:
- Payment status based on Stripe/Bill.com webhooks
- Reminder schedule based on work completion
- Aging status for reporting

### Admin Can Update:
- Both work and payment status
- Cancel/reschedule reminders
- Add payment arrangements

## 6. UI Changes Required

### Technician Job View
```jsx
// Show work status prominently
<Select value={job.work_status} onChange={updateWorkStatus}>
  <option value="work_started">Work Started</option>
  <option value="in_progress">In Progress</option>
  <option value="rough_in_complete">Rough-In Complete</option>
  <option value="work_complete">Work Complete</option>
</Select>

// Show payment status as read-only
<Badge>Payment: {job.payment_status}</Badge>
```

### Admin Job View
```jsx
// Show both statuses
<div className="status-container">
  <Badge>Work: {job.work_status}</Badge>
  <Badge>Payment: {job.payment_status}</Badge>
</div>

// Reminder controls
<div className="reminder-actions">
  <Button onClick={sendManualReminder}>Send Reminder</Button>
  <Button onClick={viewReminderHistory}>View History</Button>
</div>
```

## 7. Metrics & Monitoring

### Track Success Metrics
- Average days to payment after completion
- Reminder effectiveness (payment after each reminder type)
- Collection rate by reminder stage
- Customer payment patterns

### Admin Dashboard Widgets
- Overdue payments count & amount
- Upcoming reminders schedule
- Payment collection trend
- At-risk accounts

## 8. Edge Cases

### Partial Payments
- Continue reminders for remaining balance
- Adjust reminder content to show partial payment received

### Disputed Work
- Pause reminders when dispute logged
- Admin manual override required

### Customer Communication Preferences
- SMS reminders option
- Email unsubscribe handling
- Preferred contact method

## 9. Future Enhancements

### Phase 2 Features
- SMS reminders via Twilio
- Automated phone calls for high-value overdue
- Payment plan setup
- Late fee auto-calculation

### Phase 3 Features
- Customer portal for payment history
- Auto-pay enrollment
- Credit card on file
- Collections agency integration

## 10. Configuration

### Environment Variables
```env
# Reminder Settings
REMINDER_DAY_2_ENABLED=true
REMINDER_DAY_7_ENABLED=true
REMINDER_WEEKLY_ENABLED=true
REMINDER_LATE_FEE_PERCENTAGE=1.5
REMINDER_MAX_ATTEMPTS=12
ADMIN_ALERT_EMAIL=admin@company.com
```

### Settings Table
```sql
CREATE TABLE reminder_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key VARCHAR(100) UNIQUE,
  setting_value JSONB,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Default settings
INSERT INTO reminder_settings (setting_key, setting_value) VALUES
  ('reminder_schedule', '{"day_2": true, "day_7": true, "weekly": true}'),
  ('email_templates', '{"completion": "template_id_1", "reminder": "template_id_2"}'),
  ('escalation_rules', '{"day_30": "collections", "day_60": "legal"}');
```

## Summary

This dual-status system with automated reminders will:
1. **Clarify** the difference between work completion and payment collection
2. **Automate** the tedious task of payment follow-ups
3. **Escalate** appropriately to admin attention when needed
4. **Reduce** days sales outstanding (DSO)
5. **Improve** cash flow predictability

The system maintains flexibility for manual intervention while automating the routine aspects of payment collection.