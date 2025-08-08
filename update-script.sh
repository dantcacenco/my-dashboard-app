# Emergency fix - just remove the broken lines
sed -i '' '74,76d' app/proposals/[id]/ProposalView.tsx 2>/dev/null || sed -i '74,76d' app/proposals/[id]/ProposalView.tsx

git add -A && git commit -m "Remove broken JSX lines" && git push origin main