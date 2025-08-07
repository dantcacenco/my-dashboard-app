#!/bin/bash
# This checks if ProposalsList has correct href paths

echo "Checking ProposalsList for correct href paths..."

if [ -f "app/proposals/ProposalsList.tsx" ]; then
  echo "Current VIEW href:"
  grep -n "href.*proposals.*view" app/proposals/ProposalsList.tsx || echo "No view href found"
  
  echo ""
  echo "Current EDIT href:"
  grep -n "href.*proposals.*edit" app/proposals/ProposalsList.tsx || echo "No edit href found"
  
  echo ""
  echo "All proposal href patterns:"
  grep -n "href.*proposal" app/proposals/ProposalsList.tsx
fi
