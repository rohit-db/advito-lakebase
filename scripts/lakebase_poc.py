#!/usr/bin/env python3
"""
Advito Lakebase POC — Python Client

Connects to the Lakebase autoscaling project and runs queries.
Demonstrates both single-DB and cross-schema (FDW workaround) patterns.

Usage:
    python scripts/lakebase_poc.py                    # Run all demos
    python scripts/lakebase_poc.py --db advito_prod   # Connect to specific DB
    python scripts/lakebase_poc.py --branch dev       # Use dev branch
    python scripts/lakebase_poc.py --query "SELECT 1" # Run custom query
"""

import subprocess
import json
import sys
import argparse
from pathlib import Path

# Configuration
PROFILE = "fe-vm-serverless-jsr0s9"
WS_HOST = "https://fevm-serverless-jsr0s9.cloud.databricks.com"
PG_USER = "rohit.bhagwat@databricks.com"

ENDPOINTS = {
    "production": "ep-calm-night-d2d12480.database.us-east-1.cloud.databricks.com",
    "dev": "ep-cool-glade-d255o6al.database.us-east-1.cloud.databricks.com",
}


def get_token(branch: str = "production") -> str:
    """Generate a Postgres credential for the given branch."""
    # Get workspace token
    result = subprocess.run(
        ["databricks", "auth", "token", "--profile", PROFILE],
        capture_output=True, text=True
    )
    ws_token = json.loads(result.stdout).get("access_token") or json.loads(result.stdout).get("token_value")

    # Generate Postgres credential
    endpoint = f"projects/advito-lakebase/branches/{branch}/endpoints/primary"
    result = subprocess.run(
        ["curl", "-s", "-X", "POST",
         "-H", f"Authorization: Bearer {ws_token}",
         "-H", "Content-Type: application/json",
         "-d", json.dumps({"endpoint": endpoint}),
         f"{WS_HOST}/api/2.0/postgres/credentials"],
        capture_output=True, text=True
    )
    return json.loads(result.stdout)["token"]


def get_connection(database: str = "postgres", branch: str = "production"):
    """Get a psycopg2 connection to Lakebase."""
    try:
        import psycopg2
    except ImportError:
        print("Install psycopg2: pip install psycopg2-binary")
        sys.exit(1)

    token = get_token(branch)
    host = ENDPOINTS[branch]

    return psycopg2.connect(
        host=host,
        port=5432,
        database=database,
        user=PG_USER,
        password=token,
        sslmode="require"
    )


def run_query(conn, query: str, title: str = None):
    """Execute a query and print results."""
    if title:
        print(f"\n{'=' * 60}")
        print(f"  {title}")
        print(f"{'=' * 60}")

    cur = conn.cursor()
    cur.execute(query)

    if cur.description:
        cols = [desc[0] for desc in cur.description]
        rows = cur.fetchall()

        # Print header
        widths = [max(len(str(c)), max((len(str(r[i])) for r in rows), default=0)) for i, c in enumerate(cols)]
        header = " | ".join(c.ljust(w) for c, w in zip(cols, widths))
        sep = "-+-".join("-" * w for w in widths)
        print(header)
        print(sep)

        # Print rows
        for row in rows:
            print(" | ".join(str(v).ljust(w) for v, w in zip(row, widths)))

        print(f"\n({len(rows)} rows)")
    else:
        print(f"OK ({cur.rowcount} rows affected)")

    conn.commit()


def demo_separate_databases(branch: str = "production"):
    """Demo: Query each database independently."""
    print("\n" + "=" * 60)
    print("  DEMO 1: Separate Databases (advito_prod + advito_qsi)")
    print("=" * 60)

    # Query prod
    conn = get_connection("advito_prod", branch)
    run_query(conn, """
        SELECT c.client_name, count(*) as bookings,
               count(*) FILTER (WHERE b.leakage_flag) as leakage
        FROM bookings b JOIN clients c ON b.client_id = c.client_id
        GROUP BY c.client_name ORDER BY bookings DESC
    """, "Prod: Booking Summary by Client")
    conn.close()

    # Query QSI
    conn = get_connection("advito_qsi", branch)
    run_query(conn, """
        SELECT city, country, star_rating, avg_market_rate, median_rate
        FROM market_rates
        WHERE country = 'USA'
        ORDER BY avg_market_rate DESC LIMIT 5
    """, "QSI: Top US Market Rates")
    conn.close()

    print("\n  NOTE: Cannot join across these databases in SQL!")
    print("  Cross-DB refs fail: SELECT * FROM advito_qsi.public.market_rates")


def demo_schema_workaround(branch: str = "production"):
    """Demo: Single DB with schemas — FDW replacement."""
    print("\n" + "=" * 60)
    print("  DEMO 2: Schema Workaround (advito_unified)")
    print("  prod.* and qsi.* schemas in ONE database")
    print("=" * 60)

    conn = get_connection("advito_unified", branch)

    # Cross-schema join: Rate savings
    run_query(conn, """
        SELECT c.client_name, h.city, h.chain_name,
               b.booked_rate, mr.avg_market_rate,
               ROUND(mr.avg_market_rate - b.booked_rate, 2) AS savings,
               ROUND(100.0 * (mr.avg_market_rate - b.booked_rate) / mr.avg_market_rate, 1) AS savings_pct
        FROM prod.bookings b
        JOIN prod.hotels h ON b.hotel_id = h.hotel_id
        JOIN prod.clients c ON b.client_id = c.client_id
        JOIN qsi.market_rates mr
            ON h.city = mr.city AND h.country = mr.country
            AND h.star_rating = mr.star_rating
            AND mr.rate_date = DATE_TRUNC('month', b.check_in)
        WHERE b.rate_type = 'corporate'
        ORDER BY savings_pct DESC
    """, "Cross-Schema: Rate Savings vs Market (prod + qsi)")

    # Full pipeline
    run_query(conn, """
        SELECT c.client_name, h.property_name, b.booked_rate, b.leakage_flag,
               rp.negotiated_rate AS corp_rate, mr.avg_market_rate,
               qs.overall_score AS quality, di.demand_score AS demand,
               CASE
                   WHEN b.leakage_flag THEN 'LEAKAGE'
                   WHEN b.booked_rate <= COALESCE(rp.negotiated_rate, 0) THEN 'AT CORP RATE'
                   ELSE 'IN POLICY'
               END AS classification
        FROM prod.bookings b
        JOIN prod.clients c ON b.client_id = c.client_id
        JOIN prod.hotels h ON b.hotel_id = h.hotel_id
        LEFT JOIN prod.rate_programs rp ON b.client_id = rp.client_id AND b.hotel_id = rp.hotel_id
            AND b.check_in BETWEEN rp.effective_start AND rp.effective_end
        LEFT JOIN qsi.market_rates mr ON h.city = mr.city AND h.country = mr.country
            AND h.star_rating = mr.star_rating AND mr.rate_date = DATE_TRUNC('month', b.check_in)
        LEFT JOIN qsi.quality_scores qs ON h.chain_name = qs.hotel_chain AND h.city = qs.city
        LEFT JOIN qsi.demand_index di ON h.city = di.city AND h.country = di.country
            AND di.month = DATE_TRUNC('month', b.check_in)
        ORDER BY b.check_in LIMIT 5
    """, "Full Pipeline: All Schemas (replaces multi-FDW query)")

    conn.close()
    print("\n  This query joins prod.* AND qsi.* tables — no FDW needed!")


def main():
    parser = argparse.ArgumentParser(description="Advito Lakebase POC")
    parser.add_argument("--db", default=None, help="Database to connect to")
    parser.add_argument("--branch", default="production", choices=["production", "dev"])
    parser.add_argument("--query", default=None, help="Custom SQL query to run")
    parser.add_argument("--demo", action="store_true", help="Run full demo")
    args = parser.parse_args()

    if args.query and args.db:
        conn = get_connection(args.db, args.branch)
        run_query(conn, args.query, f"Custom Query on {args.db}")
        conn.close()
    elif args.demo or (not args.query and not args.db):
        print("Advito Lakebase POC — Feature Demonstration")
        print(f"Branch: {args.branch}")
        demo_separate_databases(args.branch)
        demo_schema_workaround(args.branch)
        print("\n" + "=" * 60)
        print("  POC Complete!")
        print("=" * 60)
    elif args.db:
        conn = get_connection(args.db, args.branch)
        print(f"Connected to {args.db} on {args.branch}")
        # Interactive-style: just verify connection
        run_query(conn, "SELECT current_database(), version()", "Connection Info")
        conn.close()


if __name__ == "__main__":
    main()
