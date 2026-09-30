import sqlite3

import pandas as pd

from src.export_model_data import build_model_data

# Columns that are only set AFTER the company responds (or are the outcome itself).
# Using them to predict "monetary relief" would be cheating (data leakage).
LEAKY = {"company_response", "company_public_response", "timely_response", "date_sent",
         "complaint_id", "company", "zip_code"}


def make_db(tmp_path):
    db = tmp_path / "t.db"
    conn = sqlite3.connect(db)
    conn.executescript(open("sql/00_schema.sql").read())
    rows = [
        (1, "2024-03-05", "2024-03-06", "Mortgage", None, "Issue A", None, "ACME", "OH", None, None, "Web", None, "Closed with monetary relief", 1),
        (2, "2024-04-05", "2024-04-06", "Mortgage", None, "Issue A", None, "ACME", None, None, "Older American", "Web", None, "Closed with explanation", 1),
        (3, "2025-01-05", "2025-01-06", "Credit card", None, "Issue B", None, "NEWCO", "TX", None, None, "Phone", None, "Closed with explanation", 1),
        (4, "2025-01-06", "2025-01-07", "Credit card", None, "Issue B", None, "ACME", "TX", None, None, "Phone", None, "Untimely response", 0),
        (5, "2025-01-07", "2025-01-08", "Credit card", None, "Issue B", None, "ACME", "TX", None, None, "Phone", None, "In progress", 1),
    ]
    conn.executemany("INSERT INTO complaints VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", rows)
    conn.commit()
    conn.close()
    return db


def test_no_leaky_columns_in_model_data(tmp_path):
    df = build_model_data(make_db(tmp_path))
    assert not (LEAKY & set(df.columns))


def test_outcome_is_monetary_relief_and_unfinished_rows_dropped(tmp_path):
    df = build_model_data(make_db(tmp_path))
    assert len(df) == 3                       # 'Untimely response' and 'In progress' rows removed
    assert df.sort_values(["year", "month"])["relief"].tolist() == [1, 0, 0]


def test_company_volume_uses_2024_only_and_defaults_to_zero(tmp_path):
    df = build_model_data(make_db(tmp_path)).set_index(["year", "month", "issue"], drop=False)
    acme = df[df["product"] == "Mortgage"]["company_volume_2024"]
    newco = df[df["product"] == "Credit card"]["company_volume_2024"]
    assert (acme == 2).all()                  # ACME had 2 complaints in 2024
    assert (newco == 0).all()                 # NEWCO never appeared in 2024


def test_missing_tags_and_state_become_explicit_levels(tmp_path):
    df = build_model_data(make_db(tmp_path))
    assert df["tags"].notna().all() and df["state"].notna().all()
    assert "None" in set(df["tags"]) and "Unknown" in set(df["state"])
