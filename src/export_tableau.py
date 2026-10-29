"""Export the dbt marts to CSV for Tableau Public.

Tableau Public cannot connect to a local DuckDB file, so the marts are
written to tableau/*.csv. Run after `dbt build` (see README):

    .venv-dbt/bin/python -m src.export_tableau
"""
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "data" / "cfpb.duckdb"
OUT = ROOT / "tableau"
MARTS = [
    "mart_monthly_product",
    "mart_company_outcomes",
    "mart_issue_outcomes",
    "mart_daily_volume",
]


def main() -> None:
    OUT.mkdir(exist_ok=True)
    con = duckdb.connect(str(DB), read_only=True)
    for mart in MARTS:
        path = OUT / f"{mart}.csv"
        con.sql(f"select * from {mart} order by all").write_csv(str(path))
        rows = con.sql(f"select count(*) from {mart}").fetchall()[0][0]
        print(f"{mart}: {rows} rows -> {path.relative_to(ROOT)}")
    con.close()


if __name__ == "__main__":
    main()
