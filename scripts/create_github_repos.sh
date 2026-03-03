#!/usr/bin/env bash
set -euo pipefail

# Creates the HRMS repositories under the authenticated GitHub user account.
# Requirements:
# - GitHub CLI (`gh`) installed and authenticated (`gh auth status`)

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI ('gh') is not installed." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Error: GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
fi

owner="$(gh api user --jq .login)"

declare -a repos=(
  "hr-frontend"
  "hr-api-gateway"
  "hr-employee-service"
  "hr-payroll-service"
  "hr-leave-service"
  "hr-notification-service"
  "hr-shared-contracts"
  "hr-infra-terraform"
  "hr-helm-charts"
  "hr-devops-templates"
)

for repo in "${repos[@]}"; do
  full_name="${owner}/${repo}"

  if gh repo view "$full_name" >/dev/null 2>&1; then
    echo "Skipping ${full_name}: already exists."
    continue
  fi

  echo "Creating ${full_name}..."
  gh repo create "$full_name" \
    --private \
    --add-readme \
    --confirm

  echo "Created ${full_name}"
done

echo "Done."
