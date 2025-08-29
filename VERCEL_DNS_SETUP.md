# DNS Records for Squarespace

## For Vercel Hosting (Add these in Squarespace DNS Settings):

### 1. Subdomain (fairairhc.service-pro.app)
Type: CNAME
Host: fairairhc
Data: cname.vercel-dns.com.
Priority: (leave blank)
TTL: 4 hours

### 2. Root Domain (optional - if you want service-pro.app to work)
Type: A
Host: @ (or leave blank)
Data: 76.76.21.21
Priority: (leave blank)
TTL: 4 hours

### 3. WWW redirect (optional)
Type: CNAME
Host: www
Data: cname.vercel-dns.com.
Priority: (leave blank)
TTL: 4 hours

## After Adding DNS Records:

1. Go back to Vercel
2. Click "Refresh" next to the domain
3. Wait 5-15 minutes
4. Domain should show green checkmark

## Test Your Domain:

Once verified, visit:
- https://fairairhc.service-pro.app
- https://fairairhc.service-pro.app/dashboard

Both should work and show your app!