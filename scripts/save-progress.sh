#!/bin/bash

###############################################################################
# Quick Save & Commit Documentation Changes
# This script helps you save your documentation work with proper git commits
###############################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== PMS Documentation Save & Commit ===${NC}\n"

# Show current status
echo -e "${YELLOW}Current changes:${NC}"
git status --short docs/

echo ""
read -p "Enter service name (analytics/apigateway/auth/portfolio/simulation): " SERVICE
read -p "Enter what you completed (e.g., 'deployment, security docs'): " WHAT

# Add changes
echo -e "\n${BLUE}Adding changes...${NC}"
git add docs/services/$SERVICE/

# Create commit
COMMIT_MSG="docs($SERVICE): expand $WHAT

- Enhanced $WHAT documentation with comprehensive details
- Added examples, code snippets, and best practices
- Improved readability and structure"

echo -e "\n${BLUE}Creating commit...${NC}"
git commit -m "$COMMIT_MSG"

echo -e "\n${GREEN}✓ Changes committed successfully!${NC}"
echo -e "\nCommit message:"
echo -e "${YELLOW}$COMMIT_MSG${NC}"

echo -e "\n${BLUE}To push changes, run:${NC}"
echo -e "  git push origin main"

# Show summary
echo -e "\n${GREEN}=== Summary ===${NC}"
git log -1 --stat
