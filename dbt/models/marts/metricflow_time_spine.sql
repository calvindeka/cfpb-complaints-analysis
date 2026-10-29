-- One row per day; the semantic layer needs it to aggregate metrics by time.
select cast(d as date) as date_day
from range(date '2024-01-01', date '2026-01-01', interval 1 day) t(d)
