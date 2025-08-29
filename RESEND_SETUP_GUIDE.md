# 🚀 RESEND SETUP GUIDE WITH service-pro.app

## 📋 Quick Setup Steps

### Step 1: Add Domain to Resend
1. Go to [Resend Dashboard](https://resend.com)
2. Click **"Domains"** in left sidebar
3. Click **"Add Domain"** button
4. Enter: `service-pro.app`
5. Click **"Add"**

### Step 2: Copy DNS Records from Resend
You'll see 3 records. They look something like this:

```
1. Verification Record:
   Type: TXT
   Name: _resend
   Value: resend-verification=r3s3nd_v3r1f1c4t10n_c0d3

2. DKIM Record:
   Type: CNAME  
   Name: resend._domainkey
   Value: resend.domainkey.r3s3nd.resend.io

3. SPF Record (may already exist):
   Type: TXT
   Name: @ 
   Value: v=spf1 include:resend.io ~all
```

### Step 3: Add DNS Records to Squarespace

1. Go to your [Squarespace account](https://account.squarespace.com)
2. Navigate to **Domains → service-pro.app → DNS Settings**
3. For each record from Resend:

#### Adding the Verification TXT Record:
- Click **"Add Record"** 
- **Type:** TXT
- **Host:** `_resend`
- **Data:** `[paste the resend-verification value]`
- **Priority:** Leave at 0
- Click **Save**

#### Adding the DKIM CNAME Record:
- Click **"Add Record"**
- **Type:** CNAME
- **Host:** `resend._domainkey`
- **Data:** `[paste the resend.domainkey value]`
- Click **Save**

#### Adding/Updating SPF Record:
⚠️ **Check if you already have an SPF record** (TXT record with @ that starts with v=spf1)

**If NO existing SPF:**
- Click **"Add Record"**
- **Type:** TXT
- **Host:** `@`
- **Data:** `v=spf1 include:resend.io ~all`
- Click **Save**

**If YES existing SPF:**
- Edit the existing record
- Add `include:resend.io` before `~all`
- Example: `v=spf1 include:_spf.google.com include:resend.io ~all`

### Step 4: Add Subdomain for Vercel

While you're in DNS settings, add the subdomain:

- Click **"Add Record"**
- **Type:** CNAME
- **Host:** `fairairhc`
- **Data:** `cname.vercel-dns.com.`
- Click **Save**

### Step 5: Verify in Resend

1. Go back to [Resend Domains](https://resend.com/domains)
2. Click **"Verify DNS Records"** next to service-pro.app
3. Wait 5-30 minutes for DNS propagation
4. You'll see green checkmarks when verified ✅

### Step 6: Update Vercel Environment Variables

1. Go to [Vercel Dashboard](https://vercel.com)
2. Select your project
3. Go to **Settings → Environment Variables**
4. Add/Update these:

```env
EMAIL_FROM=noreply@fairairhc.service-pro.app
REPLY_TO_EMAIL=dantcacenco@gmail.com
BUSINESS_EMAIL=dantcacenco@gmail.com
NEXT_PUBLIC_BASE_URL=https://fairairhc.service-pro.app
```

### Step 7: Run Database Migration

```bash
# Connect to your database and run:
psql "$DATABASE_URL" -f database_migrations/create_email_tracking_table.sql
```

Or run in Supabase SQL Editor:
1. Go to Supabase Dashboard
2. SQL Editor
3. Paste the contents of `create_email_tracking_table.sql`
4. Click **Run**

### Step 8: Test Everything

```bash
# Test email sending
npx tsx test-email.ts

# Build and test locally
npm run build
npm run dev

# Deploy to production
git add .
git commit -m "Add Resend email tracking and domain setup"
git push origin main
```

## 📊 Email Monitoring Dashboard

After setup, you'll have:
- **Automatic alerts** at 90 emails/day
- **Email tracking** in database
- **Usage stats** viewable in SQL:

```sql
-- Check today's usage
SELECT * FROM get_email_usage();

-- See recent email activity
SELECT * FROM email_usage_stats;
```

## 🎯 What Happens with Monitoring

1. **Every email sent** is tracked in the database
2. **At 90 emails** you get an alert email
3. **Alert includes** direct link to upgrade
4. **You can check usage** anytime in database

## 💰 When to Upgrade

**Free Plan:**
- 100 emails/day
- 3,000 emails/month
- Perfect for testing

**Pro Plan ($20/month):**
- No daily limit
- 5,000 emails/month
- Better for production

**Quick Math:**
- 10 proposals/day = Safe on free plan
- 15+ proposals/day = Consider upgrading
- Heavy days (20+) = Definitely upgrade

## 🔧 Troubleshooting

### DNS Not Verifying?
- Wait up to 48 hours (usually 15-30 min)
- Check records are exactly as Resend shows
- No extra spaces or characters

### Emails Not Sending?
```bash
# Check DNS propagation
nslookup -type=TXT _resend.service-pro.app

# Should return your verification code
```

### Still Using Test Mode?
Check your Resend API key:
- Test keys: Only send to your email
- Production keys: Send to anyone (after domain verified)

## 📱 Production Checklist

- [ ] Domain verified in Resend (green checkmarks)
- [ ] Email tracking table created
- [ ] Environment variables updated in Vercel
- [ ] Test email sends successfully
- [ ] Subdomain loads (fairairhc.service-pro.app)
- [ ] Alert system tested (manually update count to 90)

## 🚀 You're Ready!

Once DNS propagates and shows verified:
1. Your app can send professional emails
2. You'll get alerts before hitting limits
3. Customers see `fairairhc.service-pro.app` sender
4. Replies go to your Gmail

---

**Next Steps:**
1. Add DNS records to Squarespace NOW
2. Wait 15-30 minutes
3. Verify in Resend
4. Deploy the email tracking code
5. You're live! 🎉