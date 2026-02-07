# Documentation Scripts

This directory contains automation scripts for managing PMS platform documentation.

## Quick Start

### Expand All Documentation
```bash
cd /mnt/c/Developer/pms-org/pms-docs
chmod +x scripts/*.sh
./scripts/expand-all-docs.sh
```

### Expand Specific Service
```bash
./scripts/expand-single-service.sh analytics
./scripts/expand-single-service.sh apigateway
```

## Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `expand-all-docs.sh` | Expands all service documentation | `./expand-all-docs.sh` |
| `expand-single-service.sh` | Expands docs for one service | `./expand-single-service.sh <service>` |
| `check-completeness.sh` | Validates all docs are complete | `./check-completeness.sh` |
| `backup-docs.sh` | Creates backup of all documentation | `./backup-docs.sh` |

## Progress Tracking

Use the checklist file to track progress:

```bash
cat scripts/doc-checklist.txt
```

## Manual Expansion

If you prefer to expand manually, follow this order:

1. **Analytics Service** ✅ (COMPLETED)
   - [x] overview.md
   - [x] architecture.md
   - [x] api-contract.md
   - [x] configuration.md
   - [ ] deployment.md
   - [ ] security.md
   - [ ] failure-modes.md

2. **API Gateway**
   - [ ] overview.md
   - [ ] architecture.md
   - [ ] api-contract.md
   - [ ] configuration.md
   - [ ] deployment.md
   - [ ] security.md
   - [ ] failure-modes.md

3. **Auth Service**
   - [ ] overview.md
   - [ ] architecture.md
   - [ ] api-contract.md
   - [ ] configuration.md
   - [ ] deployment.md
   - [ ] security.md
   - [ ] failure-modes.md

4. **Portfolio Service**
   - [ ] overview.md
   - [ ] architecture.md
   - [ ] api-contract.md
   - [ ] configuration.md
   - [ ] deployment.md
   - [ ] security.md
   - [ ] failure-modes.md

5. **Simulation Service**
   - [ ] overview.md
   - [ ] architecture.md
   - [ ] api-contract.md
   - [ ] configuration.md
   - [ ] deployment.md
   - [ ] security.md
   - [ ] failure-modes.md

## Templates

Pre-made templates are available in `scripts/templates/`:
- `deployment-template.md`
- `security-template.md`
- `failure-modes-template.md`

To use a template:
```bash
cp scripts/templates/deployment-template.md docs/services/portfolio/deployment.md
# Edit placeholders: {SERVICE_NAME}, {service-name}, etc.
```

## Git Integration

After expanding documentation:

```bash
# Review changes
git diff docs/

# Commit changes
git add docs/
git commit -m "docs: expand documentation for [service-name]"

# Push changes
git push origin main
```

## Quality Checks

Before committing, run quality checks:

```bash
# Check for placeholder text
grep -r "{SERVICE_NAME}" docs/

# Check line counts (should be > 100 for each file)
find docs/services -name "*.md" -exec wc -l {} \;

# Validate markdown syntax
npm run lint:md  # if markdownlint is configured
```
