"""Load the raw CFPB CSV into SQLite using the schema in sql/00_schema.sql."""
import csv
import sqlite3
import sys
from pathlib import Path

from src.clean import clean_row

SCHEMA = Path(__file__).resolve().parent.parent / "sql" / "00_schema.sql"
COLUMNS = ["complaint_id", "date_received", "date_sent", "product", "sub_product", "issue",
           "sub_issue", "company", "state", "zip_code", "tags", "submitted_via",
           "company_public_response", "company_response", "timely_response"]


def load_csv(csv_path, db_path, rebuild=True) -> int:
    """Clean every row and insert it. Returns the number of rows loaded.

    rebuild=True drops the table first so re-running gives the same result.
    rebuild=False keeps existing rows, so re-loading the same file raises IntegrityError.
    """
    conn = sqlite3.connect(db_path)
    try:
        if rebuild:
            conn.execute("DROP TABLE IF EXISTS complaints")
        conn.executescript(SCHEMA.read_text())
        placeholders = ", ".join("?" for _ in COLUMNS)
        sql = f"INSERT INTO complaints ({', '.join(COLUMNS)}) VALUES ({placeholders})"
        n = 0
        with open(csv_path, newline="") as f:
            for raw in csv.DictReader(f):
                row = clean_row(raw)
                conn.execute(sql, [row[c] for c in COLUMNS])
                n += 1
        conn.commit()
        return n
    finally:
        conn.close()


if __name__ == "__main__":
    csv_path = sys.argv[1] if len(sys.argv) > 1 else "data/raw/complaints.csv"
    db_path = sys.argv[2] if len(sys.argv) > 2 else "data/complaints.db"
    print("loaded", load_csv(csv_path, db_path), "rows")
