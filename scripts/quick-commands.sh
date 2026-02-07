#!/bin/bash

# PMS Documentation Quick Reference
# Copy-paste these commands as needed

echo "=== PMS Documentation Commands ==="
echo ""

echo "📊 CHECK PROGRESS:"
echo "  cat scripts/progress.txt"
echo ""

echo "💾 SAVE WORK (Git):"
echo "  ./scripts/save-progress.sh"
echo "  # OR manually:"
echo "  git add docs/"
echo "  git commit -m 'docs: update [service] documentation'"
echo "  git push"
echo ""

echo "📝 VIEW CURRENT CHANGES:"
echo "  git status docs/"
echo "  git diff docs/"
echo ""

echo "📏 CHECK FILE SIZES (should be >200 lines when complete):"
echo "  wc -l docs/services/analytics/*.md"
echo "  wc -l docs/services/apigateway/*.md"
echo "  wc -l docs/services/auth/*.md"
echo "  wc -l docs/services/portfolio/*.md"
echo "  wc -l docs/services/simulation/*.md"
echo ""

echo "🔍 FIND INCOMPLETE FILES (<100 lines):"
echo "  find docs/services -name '*.md' -exec sh -c 'lines=\$(wc -l < \"\$1\"); [ \$lines -lt 100 ] && echo \"\$1: \$lines lines\"' _ {} \;"
echo ""

echo "📦 BUILD DOCUMENTATION SITE:"
echo "  npm install"
echo "  npm run build"
echo "  npm run serve  # Preview locally"
echo ""

echo "🚀 DEPLOY DOCUMENTATION:"
echo "  npm run deploy  # Deploy to GitHub Pages"
echo ""

echo "🔙 RESTORE FROM BACKUP:"
echo "  ls docs/services/analytics/.backups/"
echo "  cp docs/services/analytics/.backups/overview.md.TIMESTAMP.bak docs/services/analytics/overview.md"
echo ""

echo "🧹 CLEAN BACKUPS:"
echo "  find docs -type d -name '.backups' -exec rm -rf {} +"
echo ""

echo "✅ VALIDATE MARKDOWN:"
echo "  # Check for placeholders"
echo "  grep -r '{SERVICE_NAME}' docs/"
echo "  grep -r 'TODO' docs/"
echo ""

echo "📚 CURRENT COMPLETION STATUS:"
wc -l docs/services/analytics/*.md | tail -1
echo "  Analytics: 4/7 files complete (overview, architecture, api-contract, configuration)"
echo "  Remaining: deployment, security, failure-modes"
echo ""

echo "💡 TIPS:"
echo "  - Use Analytics service docs as template for other services"
echo "  - Each file should be 200-1000 lines when complete"
echo "  - Include: examples, tables, code snippets, troubleshooting"
echo "  - Commit frequently to save progress"
echo ""
