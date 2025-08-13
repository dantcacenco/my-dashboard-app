#!/bin/bash

# This script shows where to add the Create Job button in ProposalView
echo "Add this import at the top of ProposalView.tsx:"
echo "import CreateJobButton from './CreateJobButton'"
echo ""
echo "Add this button in the header section, next to Edit and Print buttons:"
echo "<CreateJobButton proposal={proposal} userRole={userRole} />"
echo ""
echo "The button will only appear when:"
echo "1. User is boss or admin"
echo "2. Proposal status is 'approved'"
