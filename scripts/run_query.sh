#!/bin/bash
# Run a SQL file against a Lakebase database
# Usage: ./run_query.sh <sql_file> [database] [branch]
#   sql_file: path to .sql file
#   database: postgres (default), advito_prod, advito_qsi, advito_unified
#   branch: production (default), dev

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <sql_file> [database] [branch]"
  echo "  sql_file: path to .sql file"
  echo "  database: advito_prod, advito_qsi, advito_unified (default: postgres)"
  echo "  branch: production (default), dev"
  exit 1
fi

SQL_FILE="$1"
DATABASE="${2:-postgres}"
BRANCH="${3:-production}"

PROFILE="fe-vm-serverless-jsr0s9"
WS_HOST="https://fevm-serverless-jsr0s9.cloud.databricks.com"
PG_USER="rohit.bhagwat@databricks.com"

export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Resolve endpoint host
if [ "$BRANCH" = "production" ]; then
  PG_HOST="ep-calm-night-d2d12480.database.us-east-1.cloud.databricks.com"
elif [ "$BRANCH" = "dev" ]; then
  PG_HOST="ep-cool-glade-d255o6al.database.us-east-1.cloud.databricks.com"
else
  echo "Unknown branch: $BRANCH"
  exit 1
fi

# Generate token
TOKEN=$(databricks auth token --profile $PROFILE 2>/dev/null | jq -r '.access_token // .token_value // .')
PG_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"endpoint\": \"projects/advito-lakebase/branches/$BRANCH/endpoints/primary\"}" \
  "$WS_HOST/api/2.0/postgres/credentials" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

export PGPASSWORD="$PG_TOKEN"
CONN="host=$PG_HOST port=5432 dbname=$DATABASE user=$PG_USER sslmode=require"

echo "Running $SQL_FILE against $DATABASE on $BRANCH ..."
echo ""
psql "$CONN" -f "$SQL_FILE"
