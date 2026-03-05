# Advito Lakebase POC

Proof-of-concept evaluating **Databricks Lakebase** (autoscaling tier) as a replacement for Advito's AWS RDS PostgreSQL (~16TB).

## Quick Start

### Prerequisites

1. **Databricks CLI** v0.288.0+ — `brew install databricks/tap/databricks`
2. **psql** (PostgreSQL client) — `brew install postgresql@16`
3. **Python 3.9+** with `psycopg2` — `pip install psycopg2-binary`
4. **jq** — `brew install jq`

### Authenticate

```bash
databricks auth login --host https://fevm-serverless-jsr0s9.cloud.databricks.com \
  --profile fe-vm-serverless-jsr0s9
```

### Deploy Infrastructure (Asset Bundles)

```bash
databricks bundle deploy --target dev
```

This creates:
- Lakebase autoscaling project `advito-lakebase` (PG 17.8)
- Dev branch with read-write endpoint (0.5–4 CU)
- Production branch is auto-created (0.5–8 CU)

### Load Data

```bash
# Load both databases (advito_prod + advito_qsi)
./scripts/load_data.sh

# Load the unified schema workaround demo
./scripts/run_query.sh sql/06_schema_workaround.sql advito_unified production
./scripts/run_query.sh sql/07_schema_workaround_data.sql advito_unified production
```

### Connect Interactively

```bash
# Connect to production branch (default)
./scripts/connect.sh advito_prod

# Connect to dev branch
./scripts/connect.sh advito_unified dev

# Connect to a specific database
./scripts/connect.sh advito_qsi production
```

### Run Queries

```bash
# Run cross-schema demo queries
./scripts/run_query.sh sql/08_cross_schema_queries.sql advito_unified

# Run feature tests
./scripts/run_query.sh sql/05_feature_tests.sql advito_prod

# Run Python demo (all demos)
python scripts/lakebase_poc.py

# Python: custom query
python scripts/lakebase_poc.py --db advito_unified --query "SELECT * FROM prod.hotels LIMIT 5"

# Python: use dev branch
python scripts/lakebase_poc.py --branch dev --demo
```

## Architecture

```
Lakebase Project: advito-lakebase (autoscaling, PG 17.8)
├── production branch (0.5–8 CU, scale-to-zero)
│   ├── advito_prod    ← Main app DB (hotels, bookings, travelers, clients, rate_programs)
│   ├── advito_qsi     ← Benchmarking DB (market_rates, quality_scores, demand_index, supplier_perf)
│   └── advito_unified ← FDW workaround: single DB with prod + qsi schemas
└── dev branch (0.5–4 CU, scale-to-zero)
    └── (branched from production — full data copy, write-isolated)
```

## Databases

| Database | Schema | Tables | Purpose |
|----------|--------|--------|---------|
| `advito_prod` | public | hotels (15), clients (5), travelers (10), bookings (23), rate_programs (10) | Main application |
| `advito_qsi` | public | market_rates (24), quality_scores (15), demand_index (14), supplier_performance (13) | Benchmarking/analytics |
| `advito_unified` | prod, qsi | All tables from both DBs | FDW workaround demo |

## Key Findings

### Requirements Status

| Requirement | Status | Notes |
|------------|--------|-------|
| postgres_fdw | NOT AVAILABLE | Workaround: single DB with schemas |
| dblink | NOT AVAILABLE | Workaround: app-level connection pooling |
| Cross-DB references | NOT SUPPORTED | Workaround: schema-based approach |
| Storage >= 12TB | 8TB default, **increase on request** | Product team raises limit per customer |
| PG version >= 16 | PG 17.8 | Exceeds requirement |
| Schema evolution | WORKS | ALTER TABLE ADD COLUMN on live data |
| Branching | WORKS | Full data copy + write isolation |
| pgvector | WORKS (v0.8.0) | Embeddings, HNSW/IVFFlat indexes |
| 62 extensions | AVAILABLE | PostGIS, pg_graphql, pgcrypto, hll, etc. |

### FDW Workaround: Schema-Based Approach

Since `postgres_fdw` and `dblink` are unavailable, the recommended workaround is to consolidate multiple databases into a **single database with separate schemas**:

```
-- Before (RDS): Two databases, connected via FDW
advito_prod DB  <--postgres_fdw-->  advito_qsi DB

-- After (Lakebase): One database, two schemas
advito_unified DB
  ├── prod schema   (was advito_prod)
  └── qsi schema    (was advito_qsi)
```

Cross-schema joins work natively:

```sql
-- This replaces the FDW-based cross-database query
SELECT b.booked_rate, mr.avg_market_rate
FROM prod.bookings b
JOIN qsi.market_rates mr ON ...
```

See `sql/08_cross_schema_queries.sql` for full examples.

## Project Structure

```
advito-lakebase/
├── databricks.yml                    # Asset bundle config
├── README.md                         # This file
├── FINDINGS.md                       # Detailed test results
├── scripts/
│   ├── connect.sh                    # Interactive psql connection
│   ├── run_query.sh                  # Run SQL files against Lakebase
│   ├── load_data.sh                  # Load all databases
│   └── lakebase_poc.py               # Python demo client
└── sql/
    ├── 01_advito_prod_schema.sql     # Prod DB schema
    ├── 02_advito_prod_data.sql       # Prod DB sample data
    ├── 03_advito_qsi_schema.sql      # QSI DB schema
    ├── 04_advito_qsi_data.sql        # QSI DB sample data
    ├── 05_feature_tests.sql          # Extension & feature tests
    ├── 06_schema_workaround.sql      # Unified DB schema (FDW workaround)
    ├── 07_schema_workaround_data.sql # Unified DB sample data
    └── 08_cross_schema_queries.sql   # Cross-schema query examples
```

## Workspace Info

| | |
|---|---|
| Workspace | `fevm-serverless-jsr0s9.cloud.databricks.com` |
| CLI Profile | `fe-vm-serverless-jsr0s9` |
| Production Endpoint | `ep-calm-night-d2d12480.database.us-east-1.cloud.databricks.com` |
| Dev Endpoint | `ep-cool-glade-d255o6al.database.us-east-1.cloud.databricks.com` |
| Workspace Expires | ~Mar 4, 2026 |
