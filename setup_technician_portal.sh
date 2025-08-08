
# Comprehensive type check before committing
echo "🔍 Running comprehensive type check..."
./check_types.sh

# Ask user if they want to continue despite errors
if [ -f "typescript_errors.log" ] && grep -q "error TS" typescript_errors.log 2>/dev/null; then
    echo ""
    echo "⚠️  TypeScript errors detected. Continue anyway? (y/n)"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted due to TypeScript errors"
        exit 1
    fi
fi
