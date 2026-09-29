import csv
import sqlite3

import pytest

from src.load import load_csv

HEADER = ["Date received", "Product", "Sub-product", "Issue", "Sub-issue", "Company public response",
          "Company", "State", "ZIP code", "Tags", "Submitted via", "Date sent to company",
          "Company response to consumer", "Timely response?", "Complaint ID"]


def write_csv(path, ids):
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(HEADER)
        for i in ids:
            w.writerow(["2024-01-05T00:00:00.000Z", "Mortgage", "", "Issue", "", "", "ACME", "OH",
                        "44022", "", "Web", "2024-01-06T00:00:00.000Z", "Closed", "Yes", str(i)])


def test_load_inserts_every_row(tmp_path):
    src = tmp_path / "c.csv"
    write_csv(src, [1, 2, 3])
    db = tmp_path / "c.db"
    assert load_csv(src, db) == 3
    with sqlite3.connect(db) as conn:
        assert conn.execute("SELECT COUNT(*) FROM complaints").fetchone()[0] == 3


def test_loading_same_file_twice_fails_instead_of_doubling(tmp_path):
    src = tmp_path / "c.csv"
    write_csv(src, [1, 2])
    db = tmp_path / "c.db"
    load_csv(src, db)
    with pytest.raises(sqlite3.IntegrityError):
        load_csv(src, db, rebuild=False)


def test_rebuild_replaces_existing_data(tmp_path):
    src = tmp_path / "c.csv"
    write_csv(src, [1, 2])
    db = tmp_path / "c.db"
    load_csv(src, db)
    assert load_csv(src, db) == 2  # default rebuild=True: drop and reload
