# CFPB Bank Complaints Analysis

SQL + Python analysis of public consumer complaints about **mortgages, credit cards, and checking/savings accounts** filed with the Consumer Financial Protection Bureau (CFPB) in 2024–2025.

**Questions:** How do complaint volumes move over time? Which companies and issues dominate? How often do companies respond on time, and how do complaints end?

## Data

- **Source:** CFPB Consumer Complaint Database, public search API
  `https://www.consumerfinance.gov/data-research/consumer-complaints/search/api/v1/`
- **Downloaded:** 2026-09-29 (`python -m src.download`)
- **Filters:** `date_received` 2024-01-01 to 2025-12-31; products `Mortgage`, `Credit card`, `Checking or savings account`
- **Size:** 349,119 complaints (matches the API's reported total for each product-month; the downloader fails if any chunk is short), 1,631 distinct companies
- The full database has ~8.2M complaints for 2024–2025, but ~88% are credit-reporting complaints, so I chose the products a retail bank sells.
- The raw CSV is not committed (100 MB); the downloader recreates it. The CFPB updates records over time, so a re-download later may differ slightly.

## Method

1. `src/download.py`: pulls the data one product-month at a time (the API caps a single export) and checks each chunk's row count.
2. `src/clean.py`: tested cleaning functions (date trimming to `YYYY-MM-DD`, state validation, Yes/No → 1/0, blanks → NULL).
3. `src/load.py` + `sql/00_schema.sql`: loads into SQLite; `complaint_id` is the primary key and `CHECK` constraints reject malformed dates.
4. `sql/01…08_*.sql`: the analysis queries (joins, GROUP BY/HAVING, CTEs, window functions `ROW_NUMBER`/`LAG`/`SUM() OVER`, date functions).
5. `src/analyze.py`: runs every query, writes `outputs/*.csv` and charts.

## Findings (all numbers from the queries in `sql/`, results in `outputs/`)

**Volume.** 150,249 complaints in 2024 and 198,870 in 2025. Monthly totals sat between about 11,000 and 14,000 through 2024, then between about 13,000 and 18,000 in 2025 (Q1, Q6).

**A January 2025 spike.** 29,644 complaints in January 2025, up 123% from December 2024, then down 55% in February (Q6). Q8 shows it is concentrated: **Navy Federal Credit Union** received 7,638 complaints that month (23.7× its average 2024 month) and **Capital One** 5,754 (7.6×). Both are almost entirely checking/savings complaints (7,411 of Navy Federal's, 4,759 of Capital One's), and Jan 15–18 alone holds 11,773 of January's 29,644 complaints (40%). For Capital One, 4,474 of its 5,754 were "Managing an account"; Navy Federal's issue mix is different (only 276 under that issue). The data does not say why; I do not claim a cause.

![monthly](outputs/monthly_total.png)

**Top companies by raw count** (Q2): JPMorgan Chase (28,234), Capital One (26,968), Wells Fargo (22,564), Citibank (21,791), Bank of America (20,233). These are raw counts, not per customer, so bigger banks naturally rank higher.

**Top issue** (Q3): "Managing an account" is the #1 issue for four of the five largest companies (Bank of America, Capital One, JPMorgan Chase, Wells Fargo). For Citibank the top issue is "Problem with a purchase shown on your statement" (5,192).

**Timely responses** (Q4): 98.67% for mortgages, 99.32% for checking/savings, 99.71% for credit cards.

**Outcomes** (Q5): most complaints close "with explanation": 94.9% of mortgage, 81.9% of checking/savings, 64.1% of credit-card complaints. Credit-card complaints end with monetary or non-monetary relief far more often (12.9% and 22.9%) than mortgage complaints (1.9% and 2.7%).

![outcomes](outputs/outcomes_by_product.png)

**Days to reach the company** (Q7): the CFPB forwards a complaint on average 0.99 (checking), 1.18 (credit card), and 2.39 (mortgage) days after receiving it.

## Limitations

- **Not a random sample.** These are only consumers who chose to complain. Findings describe complaints, not customer experience in general.
- **Volume is not harm.** Big companies have more customers. Without customer counts I cannot compute a complaint rate, so company rankings are not a ranking of quality.
- **Product labels are imperfect.** 43,936 rows (12.6%) belong to Equifax, TransUnion and Experian, which appear under these products (mostly "Credit card"). They are credit bureaus, not banks, so I left them in and flag them here rather than silently dropping them.
- **No dispute data.** The "Consumer disputed?" field was discontinued by the CFPB in 2017 and is not in this dataset, so no dispute-rate analysis.
- **Response time is not measured.** The dataset has only a timely/untimely flag and the date the CFPB sent the complaint to the company. Q7 measures the CFPB's forwarding time, not company response time.
- `timely_response = 0` is 2,031 rows while `company_response = 'Untimely response'` is 405; these are different fields and I did not reconcile them.
- 1,951 rows have no state (stored as NULL).

## Reproduce

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python -m src.download      # ~10 min; rate-limited API
python -m pytest -q         # 9 tests
python -m src.load          # builds data/complaints.db
python -m src.analyze       # writes outputs/
sqlite3 data/complaints.db < sql/01_volume_by_product_month.sql   # or run any query directly
```
