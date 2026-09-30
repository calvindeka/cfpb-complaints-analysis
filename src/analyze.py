"""Run every sql/NN_*.sql query against the database, save results as CSV, and draw charts."""
import sqlite3
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

DB = "data/complaints.db"
OUT = Path("outputs")


def run_queries():
    OUT.mkdir(exist_ok=True)
    results = {}
    with sqlite3.connect(DB) as conn:
        for f in sorted(Path("sql").glob("[0-9][0-9]_*.sql")):
            if f.name.startswith(("00", "14")):
                continue  # 00 = schema, 14 = modeling table (exported for R, not an analysis result)
            df = pd.read_sql_query(f.read_text(), conn)
            df.to_csv(OUT / f"{f.stem}.csv", index=False)
            results[f.stem] = df
    return results


def charts(r):
    v = r["01_volume_by_product_month"].pivot(index="month", columns="product", values="complaints")
    ax = v.plot(figsize=(10, 5), marker="o")
    ax.set(title="Complaints per month by product (CFPB, 2024-2025)", xlabel="", ylabel="Complaints")
    plt.xticks(rotation=45); plt.tight_layout(); plt.savefig(OUT / "volume_by_product_month.png", dpi=130); plt.close()

    t = r["02_top_companies"].head(10).iloc[::-1]
    ax = t.plot.barh(x="company", y="complaints", legend=False, figsize=(9, 5))
    ax.set(title="Top 10 companies by complaint count (raw counts, not per customer)", xlabel="Complaints", ylabel="")
    plt.tight_layout(); plt.savefig(OUT / "top_companies.png", dpi=130); plt.close()

    o = r["05_outcomes_by_product"].pivot(index="product", columns="company_response", values="pct_of_product").fillna(0)
    ax = o.plot.barh(stacked=True, figsize=(10, 4))
    ax.set(title="How complaints ended, by product (% of product)", xlabel="%", ylabel="")
    plt.tight_layout(); plt.savefig(OUT / "outcomes_by_product.png", dpi=130); plt.close()

    d = r["10_check_spike_daily"]
    d = d[(d["day"] >= "2024-12-15") & (d["day"] <= "2025-02-15")].set_index("day")
    ax = d[["navy_federal", "capital_one", "all_others"]].plot.area(figsize=(11, 4), linewidth=0)
    ax.set(title="Daily complaints, Dec 15 2024 - Feb 15 2025: the spike is a multi-day surge", xlabel="", ylabel="Complaints")
    ax.set_xticks(range(0, len(d), 7)); ax.set_xticklabels(d.index[::7], rotation=45, ha="right")
    plt.tight_layout(); plt.savefig(OUT / "spike_daily.png", dpi=130); plt.close()

    m = r["06_month_over_month"]
    ax = m.plot.bar(x="month", y="complaints", legend=False, figsize=(10, 4))
    ax.set(title="Total complaints per month (note Jan 2025 spike)", xlabel="", ylabel="Complaints")
    plt.tight_layout(); plt.savefig(OUT / "monthly_total.png", dpi=130); plt.close()


if __name__ == "__main__":
    res = run_queries()
    charts(res)
    print("wrote", len(res), "result files and 5 charts to outputs/")
