# Tableau dashboard

The CSVs here are the dbt marts, exported by `src/export_tableau.py`. Each one is small and already aggregated, so Tableau Public can load them directly.

| File | Rows | Use |
|---|---|---|
| `mart_monthly_product.csv` | 72 | Line chart: complaints per month by product (shows the January 2025 spike) |
| `mart_daily_volume.csv` | 270 | Area chart: daily complaints Dec 2024 - Feb 2025, Navy Federal and Capital One vs everyone else |
| `mart_issue_outcomes.csv` | 26 | Bar chart: monetary relief rate by issue, colored by product |
| `mart_company_outcomes.csv` | 152 | Scatter: complaints (log scale) vs monetary relief rate per company, colored by size band |

**Published dashboard:** [CFPB Bank Complaints 2024-2025 on Tableau Public](https://public.tableau.com/app/profile/calvin.deka/viz/CFPBBankComplaints2024-2025/CFPBBankComplaints2024-2025volumetheJanuary2025surgeandmonetaryrelief)

It has three views: monthly complaints (the January 2025 spike), monetary relief rate by product and issue, and daily complaints for Dec 2024 - Feb 2025 split into Navy Federal, Capital One and all other companies. The company-outcomes mart is exported but not yet charted.
