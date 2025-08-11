#!/bin/bash

echo "🔍 Running TypeScript type check..."
npx tsc --noEmit

if [ $? -eq 0 ]; then
  echo "✅ No type errors found!"
  exit 0
else
  echo "❌ Type errors detected. Please fix before committing."
  exit 1
fi
