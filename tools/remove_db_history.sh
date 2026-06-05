#!/usr/bin/env bash
set -euo pipefail

echo "This script prepares commands to remove backend/db.sqlite3 from git history. (moved from scripts/)"
echo "It will NOT run automatically. Review before executing."

cat <<'EOF'
# Recommended (requires git-filter-repo):
# Install: pip install git-filter-repo
# Then run (from repo root):
git filter-repo --path backend/db.sqlite3 --invert-paths

# Alternative using BFG (Java required):
# bfg --delete-files db.sqlite3
# git reflog expire --expire=now --all && git gc --prune=now --aggressive

echo "After running history rewrite, force-push to update remote: git push --force --all && git push --force --tags"
EOF

echo "Script prepared. Execute the recommended commands manually after reviewing."
