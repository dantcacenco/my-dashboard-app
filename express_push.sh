#!/bin/bash

# Express push - Skip all checks, just commit and push
# Use when you're confident or need to push config/docs

if [ -z "$1" ]; then
    echo "Usage: ./express_push.sh 'your commit message'"
    exit 1
fi

echo "🚀 Express Push (no checks)"
echo ""

git add -A
git commit -m "$1" || {
    echo "ℹ️  No changes to commit"
    exit 0
}

git push origin main

echo "✅ Pushed to GitHub!"
