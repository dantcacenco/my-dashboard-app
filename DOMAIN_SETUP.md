# Domain & Email Setup Guide for service-pro.app

## 🌐 Domain Configuration

### Your Setup:
- **Root Domain:** `service-pro.app`
- **Client Subdomain:** `fairairhc.service-pro.app` 
- **App URL:** `https://fairairhc.service-pro.app`

## 📋 Step-by-Step Setup

### 1️⃣ DNS Configuration at Your Domain Provider

Add these DNS records where you bought `service-pro.app`:

#### For Vercel Hosting (Subdomain):
```dns
# Option A: CNAME Record (preferred)
Type: CNAME
Name: fairairhc
Value: cname.vercel-dns.com.

# Option B: A Record (if CNAME not supported)
Type: A
Name: fairairhc
Value: 76.76.21.21
```

#### For Resend Email (Root Domain):
```dns
# Resend Verification
Type: TXT
Name: _resend
Value: [Copy from Resend dashboard]

# SPF Record
Type: TXT
Name: @
Value: v=spf1 include:resend.io ~all

# DKIM Record
Type: CNAME
Name: resend._domainkey
Value: [Copy from Resend dashboard]
```

### 2️⃣ Vercel Configuration

1. Go to [Vercel Dashboard](https://vercel.com)
2. Select your project
3. Go to **Settings → Domains**
4. Click **Add** and enter: `fairairhc.service-pro.app`
5. Vercel will verify DNS automatically

### 3️⃣ Resend Configuration

1. Go to [Resend Dashboard](https://resend.com)
2. Click **Domains → Add Domain**
3. Enter: `service-pro.app`
4. Copy the DNS records shown
5. Add them to your domain provider
6. Click **Verify DNS Records**

### 4️⃣ Environment Variables

**Local Development** (`.env.local`):
```env
# Email Configuration
EMAIL_FROM=noreply@fairairhc.service-pro.app
REPLY_TO_EMAIL=dantcacenco@gmail.com  # Testing
BUSINESS_EMAIL=dantcacenco@gmail.com

# App URL
NEXT_PUBLIC_BASE_URL=https://fairairhc.service-pro.app
```

**Production** (Vercel Dashboard):
```env
# Email Configuration
EMAIL_FROM=noreply@fairairhc.service-pro.app
REPLY_TO_EMAIL=fairairhc@gmail.com  # Production
BUSINESS_EMAIL=fairairhc@gmail.com

# App URL
NEXT_PUBLIC_BASE_URL=https://fairairhc.service-pro.app
```

## 📧 Email Flow Explanation

### How It Works:
1. **From Address:** `noreply@fairairhc.service-pro.app`
   - This is what customers see as the sender
   - Professional appearance
   - Branded to the subdomain

2. **Reply-To Address:** 
   - **Testing:** `dantcacenco@gmail.com`
   - **Production:** `fairairhc@gmail.com`
   - When customers hit "Reply", email goes here
   - No need to set up email hosting

3. **Benefits:**
   - ✅ Professional branded emails
   - ✅ Replies go to real Gmail inbox
   - ✅ No email hosting needed
   - ✅ Easy to manage

## 🧪 Testing

### Test Email Setup:
```bash
# Run after DNS propagation (5-30 minutes)
npx tsx test-email.ts
```

### Test Checklist:
- [ ] Domain verified in Resend (green checkmark)
- [ ] Test email sends successfully
- [ ] Reply-to works (reply goes to Gmail)
- [ ] Subdomain loads in browser
- [ ] Proposal emails have correct links

## 🚀 Deployment

```bash
# After all configuration
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Test build
npm run build

# Commit changes
git add .
git commit -m "Configure fairairhc.service-pro.app domain and email"
git push origin main

# Vercel auto-deploys on push
```

## 🔄 Multi-Tenant Expansion

For future clients, repeat with new subdomains:

```
client1.service-pro.app
client2.service-pro.app
client3.service-pro.app
```

Each can have their own:
- Subdomain URL
- From address (noreply@client.service-pro.app)
- Reply-to address (their Gmail)

## ⚠️ Common Issues & Solutions

### DNS Not Propagating:
- Wait up to 48 hours (usually 5-30 minutes)
- Use [DNS Checker](https://dnschecker.org) to verify

### Email Not Sending:
- Check Resend domain is verified
- Ensure DNS records are exact (copy/paste)
- Check API key is correct

### Subdomain Not Loading:
- Verify DNS records in domain provider
- Check Vercel shows domain as configured
- Clear browser cache

## 📝 Notes

- **Testing Phase:** All replies go to dantcacenco@gmail.com
- **Production:** Update REPLY_TO_EMAIL to fairairhc@gmail.com
- **Billing:** Resend free tier = 3,000 emails/month
- **Multiple Clients:** Each subdomain can have unique config
