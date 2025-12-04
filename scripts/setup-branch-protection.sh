#!/bin/bash

# =============================================================================
# GitHub Branch Protection Setup Script
# =============================================================================
# This script configures branch protection rules for the main branch.
#
# Prerequisites:
#   1. Install GitHub CLI: brew install gh
#   2. Authenticate: gh auth login
#
# Usage: ./scripts/setup-branch-protection.sh
# =============================================================================

set -e

# Configuration
OWNER="tattva20"
REPO="StreamingVideoApp"
BRANCH="main"

echo "🔐 Setting up branch protection for $OWNER/$REPO..."

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "   Install it with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "   Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI authenticated"

# Get the authenticated user
CURRENT_USER=$(gh api user --jq '.login')
echo "👤 Authenticated as: $CURRENT_USER"

# Apply branch protection rules using GitHub API
echo ""
echo "📋 Applying branch protection rules..."

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$OWNER/$REPO/branches/$BRANCH/protection" \
  -f required_status_checks='{"strict":true,"contexts":["build-ios","build-macos"]}' \
  -f enforce_admins=false \
  -f required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
  -f restrictions=null \
  -F allow_force_pushes=true \
  -F allow_deletions=false \
  -F block_creations=false \
  -F required_conversation_resolution=true

echo ""
echo "✅ Branch protection rules applied!"
echo ""
echo "📜 Summary of rules applied to '$BRANCH' branch:"
echo "   ├─ ✓ Require pull request before merging"
echo "   ├─ ✓ Require 1 approval"
echo "   ├─ ✓ Dismiss stale reviews on new commits"
echo "   ├─ ✓ Require status checks: build-ios, build-macos"
echo "   ├─ ✓ Require branch to be up to date before merging"
echo "   ├─ ✓ Require conversation resolution"
echo "   ├─ ✓ Allow force pushes (for repo owner)"
echo "   └─ ✗ Do not enforce for admins (you can bypass)"
echo ""
echo "🎉 Done! Your repository is now protected."
echo ""
echo "📝 To verify, visit:"
echo "   https://github.com/$OWNER/$REPO/settings/branches"
