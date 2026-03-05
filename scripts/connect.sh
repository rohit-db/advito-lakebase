#!/bin/bash
# Connect to Lakebase advito-lakebase project
# Usage: ./connect.sh [database] [branch]
#   database: postgres (default), advito_prod, advito_qsi, advito_unified
#   branch: production (default), dev

set -e

PROFILE="fe-vm-serverless-jsr0s9"
WS_HOST="https://fevm-serverless-jsr0s9.cloud.databricks.com"
DATABASE="${1:-postgres}"
BRANCH="${2:-production}"
PG_USER="rohit.bhagwat@databricks.com"

export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Resolve endpoint host
if [ "$BRANCH" = "production" ]; then
  PG_HOST="ep-calm-night-d2d12480.database.us-east-1.cloud.databricks.com"
elif [ "$BRANCH" = "dev" ]; then
  PG_HOST="ep-cool-glade-d255o6al.database.us-east-1.cloud.databricks.com"
else
  echo "Unknown branch: $BRANCH (use 'production' or 'dev')"
  exit 1
fi

# Generate token
echo "Generating credential for branch: $BRANCH ..."
TOKEN=$(databricks auth token --profile $PROFILE 2>/dev/null | jq -r '.access_token // .token_value // .')
PG_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"endpoint\": \"projects/advito-lakebase/branches/$BRANCH/endpoints/primary\"}" \
  "$WS_HOST/api/2.0/postgres/credentials" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

echo "Connecting to $DATABASE on $BRANCH ($PG_HOST) ..."
PGPASSWORD="$PG_TOKEN" psql "host=$PG_HOST port=5432 dbname=$DATABASE user=$PG_USER sslmode=require"
