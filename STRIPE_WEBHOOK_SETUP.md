# Stripe Webhook Configuration

## IMPORTANT: Required for Payment Processing

The payment system requires both a redirect handler AND a webhook to properly process payments.

### 1. Set up Stripe Webhook Endpoint

Go to your Stripe Dashboard:
1. Navigate to Developers → Webhooks
2. Click "Add endpoint"
3. Enter the endpoint URL: `https://my-dashboard-app-tau.vercel.app/api/stripe/webhook`
4. Select events to listen to:
   - `checkout.session.completed`
5. Click "Add endpoint"

### 2. Get the Webhook Signing Secret

After creating the webhook:
1. Click on the webhook you just created
2. Find "Signing secret" section
3. Click "Reveal" and copy the secret (starts with `whsec_`)

### 3. Add to Vercel Environment Variables

In your Vercel project settings:
1. Go to Settings → Environment Variables
2. Add: `STRIPE_WEBHOOK_SECRET` with the value from step 2
3. Redeploy your application

### 4. Test the Webhook

You can test using Stripe CLI:
```bash
stripe listen --forward-to localhost:3000/api/stripe/webhook
```

Or use the "Send test webhook" feature in Stripe Dashboard.

## How the Payment Flow Works

1. Customer clicks "Pay Now" → Redirected to Stripe
2. Customer completes payment on Stripe
3. Stripe sends webhook to `/api/stripe/webhook` (updates database)
4. Customer is redirected to `/api/payment-success` (simple redirect)
5. Customer lands back on proposal page with updated payment status

## Troubleshooting

If payments aren't updating:
1. Check Vercel Function Logs for `/api/stripe/webhook`
2. Check Stripe Dashboard → Developers → Webhooks → Event logs
3. Ensure `STRIPE_WEBHOOK_SECRET` is correctly set in Vercel
4. Check that the webhook endpoint URL is correct
