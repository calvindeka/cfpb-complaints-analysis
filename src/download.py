"""Download CFPB complaints (2024-2025; three products) in monthly chunks.

The API caps a single CSV export, so we request one product-month at a time
and check each chunk's row count against the count the API reports.
"""
import csv
import calendar
import io
import time
from pathlib import Path

import requests

BASE = "https://www.consumerfinance.gov/data-research/consumer-complaints/search/api/v1/"
PRODUCTS = ["Mortgage", "Credit card", "Checking or savings account"]
OUT = Path("data/raw/complaints.csv")


def month_ranges(years=(2024, 2025)):
    for y in years:
        for m in range(1, 13):
            last = calendar.monthrange(y, m)[1]
            yield f"{y}-{m:02d}-01", f"{y}-{m:02d}-{last:02d}"


def get(params, retries=6):
    for attempt in range(retries):
        time.sleep(2)  # be polite: the API rate-limits (HTTP 429)
        r = requests.get(BASE, params=params, timeout=120)
        if r.ok:
            return r
        time.sleep(10 * 2 ** attempt)
    r.raise_for_status()


def expected_count(product, start, end):
    r = get({"size": 0, "product": product, "date_received_min": start, "date_received_max": end})
    return r.json()["hits"]["total"]["value"]


def fetch_chunk(product, start, end):
    params = {"format": "csv", "no_aggs": "true", "size": 100000, "product": product,
              "date_received_min": start, "date_received_max": end}
    text = get(params).text
    return list(csv.reader(io.StringIO(text)))


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    header, total = None, 0
    with OUT.open("w", newline="") as f:
        w = csv.writer(f)
        for start, end in month_ranges():
            for product in PRODUCTS:
                want = expected_count(product, start, end)
                rows = fetch_chunk(product, start, end)
                head, body = rows[0], rows[1:]
                if len(body) != want:
                    raise RuntimeError(f"{product} {start}: got {len(body)}, API says {want}")
                if header is None:
                    header = head
                    w.writerow(header)
                w.writerows(body)
                total += len(body)
            print(f"{start[:7]} ok, running total {total}", flush=True)
    print("done:", total)


if __name__ == "__main__":
    main()
