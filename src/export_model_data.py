"""Run sql/14_model_data.sql and write data/model_data.csv for the R model."""
import sqlite3
from pathlib import Path

import pandas as pd

SQL = Path(__file__).resolve().parent.parent / "sql" / "14_model_data.sql"


def build_model_data(db_path) -> pd.DataFrame:
    with sqlite3.connect(db_path) as conn:
        return pd.read_sql_query(SQL.read_text(), conn)


if __name__ == "__main__":
    df = build_model_data("data/complaints.db")
    df.to_csv("data/model_data.csv", index=False)
    print("wrote data/model_data.csv:", len(df), "rows,", list(df.columns))
