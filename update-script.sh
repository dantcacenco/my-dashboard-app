#!/bin/bash

echo "🔧 Fixing TypeScript error in PaymentStages..."

# Fix the error type handling in PaymentStages
perl -i -pe 's/} catch \(error\) {/} catch (error: any) {/' app/components/PaymentStages.tsx

# Also fix any other catch blocks that might have the same issue
perl -i -pe 's/} catch \(error: any\) {/} catch (error: any) {/g' app/components/PaymentStages.tsx

# Commit the fix
git add .
git commit -m "fix: add TypeScript type annotation for error handling"
git push origin main

echo "✅ Fixed TypeScript error!"
echo ""
echo "The error object is now properly typed as 'any' to access its properties."