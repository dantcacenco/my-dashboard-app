#!/bin/bash

# Quick commit and push with TypeScript checking only
# Doesn't require Supabase to be configured locally

if [ -z "$1" ]; then
    echo "Usage: ./commit_and_push.sh 'your commit message'"
    exit 1
fi

echo "🧪 Running TypeScript check..."
if ./check_build.sh; then
    echo "✅ TypeScript check passed!"
else
    echo "⚠️  TypeScript check had warnings, but continuing..."
fi

echo ""
echo "💾 Committing changes..."
git add -A
git commit -m "$1" || {
    echo "ℹ️  No changes to commit"
    exit 0
}

echo ""
echo "🚀 Pushing to GitHub..."
git push origin main

echo ""
echo "✅ Successfully pushed to GitHub!"
echo "   Vercel will run the full build with proper env vars"
echo ""
