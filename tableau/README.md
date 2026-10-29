# Tableau dashboard

The CSVs here are the dbt marts, exported by `src/export_tableau.py`. Each one is small and already aggregated, so Tableau Public can load them directly.

| File | Rows | Use |
|---|---|---|
| `mart_monthly_product.csv` | 72 | Line chart: complaints per month by product (shows the January 2025 spike) |
| `mart_daily_volume.csv` | 270 | Area chart: daily complaints Dec 2024 - Feb 2025, Navy Federal and Capital One vs everyone else |
| `mart_issue_outcomes.csv` | 26 | Bar chart: monetary relief rate by issue, colored by product |
| `mart_company_outcomes.csv` | 152 | Scatter: complaints (log scale) vs monetary relief rate per company, colored by size band |

Published dashboard: _link added after publishing_
