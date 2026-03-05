#!/bin/bash
# Load schema and data into Lakebase databases
set -e

PROFILE="fe-vm-serverless-jsr0s9"
WS_HOST="https://fevm-serverless-jsr0s9.cloud.databricks.com"
PG_HOST="ep-calm-night-d2d12480.database.us-east-1.cloud.databricks.com"
PG_USER="rohit.bhagwat@databricks.com"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_DIR="$SCRIPT_DIR/../sql"

export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Get fresh token
echo "Generating Postgres credential..."
TOKEN=$(databricks auth token --profile $PROFILE 2>/dev/null | jq -r '.access_token // .token_value // .')
PG_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"endpoint\": \"projects/advito-lakebase/branches/production/endpoints/primary\"}" \
  "$WS_HOST/api/2.0/postgres/credentials" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

export PGPASSWORD="$PG_TOKEN"
CONN="host=$PG_HOST port=5432 user=$PG_USER sslmode=require"

echo "=== Loading advito_prod schema ==="
psql "$CONN dbname=advito_prod" -f "$SQL_DIR/01_advito_prod_schema.sql"

echo "=== Loading advito_prod data ==="
psql "$CONN dbname=advito_prod" -f "$SQL_DIR/02_advito_prod_data.sql"

echo "=== Loading advito_qsi schema ==="
psql "$CONN dbname=advito_qsi" -f "$SQL_DIR/03_advito_qsi_schema.sql"

echo "=== Loading advito_qsi data ==="
psql "$CONN dbname=advito_qsi" -f "$SQL_DIR/04_advito_qsi_data.sql"

echo ""
echo "=== Verification ==="
echo "--- advito_prod tables ---"
psql "$CONN dbname=advito_prod" -c "SELECT tablename, (SELECT count(*) FROM advito_prod.public.\"\$1\" ) FROM pg_tables WHERE schemaname='public';" 2>/dev/null || \
psql "$CONN dbname=advito_prod" -c "\dt+"

echo "--- advito_qsi tables ---"
psql "$CONN dbname=advito_qsi" -c "\dt+"

echo ""
echo "Done! Both databases loaded."
