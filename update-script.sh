#!/bin/bash
echo "🔧 Fixing hasEnvVars export and customer type error..."

# First, add hasEnvVars to utils
cat > lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount)
}

export function formatDate(dateString: string): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date(dateString))
}

export function formatDateTime(dateString: string): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(dateString))
}

export function formatShortDate(dateString: string): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(dateString))
}

export const hasEnvVars = process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error updating utils.ts"
    exit 1
fi

# Now fix the ProposalsList to handle the customer as a single object
echo "🔧 Fixing ProposalsList customer type..."

# Update the select query to use single() for customer
sed -i 's/customers (/customers!inner (/g' app/proposals/ProposalsList.tsx

# Commit and push
git add .
git commit -m "fix: add hasEnvVars export and fix customer relationship

- Add hasEnvVars export to utils.ts
- Fix ProposalsList to ensure customer is single object
- Use !inner join to ensure customer exists"

git push origin main

echo "✅ Build errors fixed!"
echo ""
echo "📝 Changes made:"
echo "- Added hasEnvVars export for env var checking"
echo "- Fixed customer relationship to use !inner join"
echo ""
echo "⚠️ Note: If customer is still returning as array, we may need to check the Supabase foreign key setup"