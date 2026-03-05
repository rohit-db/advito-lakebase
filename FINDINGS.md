# Advito Lakebase POC — Findings

## Overview

Lakebase autoscaling POC evaluating Databricks Lakebase as a replacement for Advito's AWS RDS PostgreSQL (~16TB). Tested against key requirements from the BCD/Advito migration workstream.

**Workspace**: `fevm-serverless-jsr0s9`
**Project**: `advito-lakebase` (autoscaling tier)
**PG Version**: 17.8
**Test Date**: 2026-03-02

---

## Infrastructure

| Component | Details |
|-----------|---------|
| Bundle | `databricks.yml` — deploy with `databricks bundle deploy` |
| Production branch | `ep-calm-night-d2d12480` / 0.5–8 CU autoscaling |
| Dev branch | `ep-cool-glade-d255o6al` / 0.5–4 CU autoscaling |
| Databases | `advito_prod` (5 tables), `advito_qsi` (4 tables) |

---

## Requirements vs. Current State

| # | Requirement | Status | Details |
|---|------------|--------|---------|
| 1 | **postgres_fdw** — cross-instance queries | NOT AVAILABLE | Extension not installed in serverless environment. No alternative extension exists. |
| 2 | **dblink** — parallel connections within SQL functions | NOT AVAILABLE | Extension not installed in serverless environment. |
| 3 | **Cross-database references** (e.g., `db.schema.table`) | NOT SUPPORTED | Standard PG limitation — cross-DB refs not implemented even within same project. |
| 4 | **Storage ≥ 12TB** (ideally 16TB) | OK — 8TB default, increase on request | `branch_logical_size_limit_bytes` = 8TB default. Product team can increase per customer request. |
| 5 | **Migration path** — RDS (Ohio) → Lakebase (Virginia), cross-region/cross-account | UNTESTED | pg_dump/restore or Spark parallel read are options. Not yet tested in this POC. |
| 6 | **PG version upgrade** — currently < v15, Lakebase requires v16+ | N/A — Lakebase is PG 17.8 | Advito must upgrade RDS to v15+ before migration, or migrate directly with schema compatibility testing. |
| 7 | **Schema evolution** — Lakebase ↔ Lakehouse sync | WORKS (Lakebase side) | `ALTER TABLE ADD COLUMN` succeeds on live data. UC sync side (synced tables) not yet tested. |

---

## Feature Test Results

### Extensions & Compatibility

| Feature | Result | Notes |
|---------|--------|-------|
| postgres_fdw | NOT AVAILABLE | Confirmed missing from serverless env |
| dblink | NOT AVAILABLE | Confirmed missing from serverless env |
| pgvector | WORKS (v0.8.0) | `vector(N)` type, HNSW/IVFFlat indexes |
| PostGIS | AVAILABLE (v3.5.0) | Not yet tested — available for geospatial queries |
| pg_graphql | AVAILABLE (v1.5.11) | GraphQL over Postgres — not yet tested |
| JSONB + GIN indexes | WORKS | Containment queries (`@>`), key extraction |
| pg_trgm (fuzzy search) | WORKS | Trigram similarity, `%` operator, GIN indexes |
| pgcrypto | AVAILABLE (v1.3) | Cryptographic functions |
| uuid-ossp | AVAILABLE (v1.1) | UUID generation |
| hstore | AVAILABLE (v1.8) | Key-value pairs |
| hll (HyperLogLog) | AVAILABLE (v2.19) | Approximate distinct counts |
| pg_hint_plan | AVAILABLE (v1.7.0) | Query plan hints |
| pg_stat_statements | AVAILABLE (v1.11) | Query statistics |
| **Total extensions** | **62 available** | Full list in `sql/05_feature_tests.sql` |

### Branching & Isolation

| Test | Result |
|------|--------|
| Branch data inheritance | WORKS — dev branch has full copy of production data at branch point |
| Branch write isolation | WORKS — writes to dev do NOT appear in production |
| Branch recreation | WORKS — delete + recreate from current production state |
| Endpoint per branch | WORKS — each branch gets its own connection endpoint |

### Autoscaling

| Setting | Production | Dev |
|---------|-----------|-----|
| Min CU | 0.5 | 0.5 |
| Max CU | 8.0 | 4.0 |
| Scale-to-zero | Yes | Yes |

---

## Workarounds for FDW / Cross-DB Queries

Since `postgres_fdw`, `dblink`, and cross-database references are all unavailable, here are alternatives to evaluate:

1. **Merge into single database with schemas** — Move `advito_qsi` tables into `advito_prod` under a `qsi` schema. Eliminates cross-DB need entirely. Simplest option.

2. **Application-level joins** — Query each database separately, join results in the application layer. Works but adds latency and complexity.

3. **Sync both DBs to Delta Lake** — Use Lakebase → UC synced tables for both databases. Cross-DB analytics happen in Spark SQL / Databricks SQL warehouse instead of Postgres. Best for analytics workloads.

4. **Dual connections in application code** — Replace dblink's parallel connection pattern with application-level connection pooling (e.g., PgBouncer or app-side async queries).

---

## Project Structure

```
advito-lakebase/
├── databricks.yml              # Asset bundle — project + dev branch + endpoint
├── scripts/
│   └── load_data.sh            # Load schema + data into both databases
├── sql/
│   ├── 01_advito_prod_schema.sql
│   ├── 02_advito_prod_data.sql
│   ├── 03_advito_qsi_schema.sql
│   ├── 04_advito_qsi_data.sql
│   └── 05_feature_tests.sql
└── FINDINGS.md                 # This file
```

---

## Next Steps

- [ ] Test UC sync (synced database tables) for schema evolution verification
- [ ] Test pg_dump/restore migration path from RDS
- [ ] Evaluate single-DB-with-schemas approach as FDW replacement
- [ ] Get updated timeline on storage limit increase beyond 8TB
- [ ] Test Data API (PostgREST) for application integration
