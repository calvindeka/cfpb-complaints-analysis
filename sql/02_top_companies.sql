-- Q2: Which companies have the most complaints?
-- CAVEAT: raw counts, not per-customer. Big banks have more customers, so more complaints.
-- HAVING filters AFTER grouping (WHERE filters rows BEFORE grouping).
SELECT company,
       COUNT(*)                                              AS complaints,
       ROUND(100.0 * SUM(timely_response) / COUNT(*), 1)     AS pct_timely
FROM complaints
GROUP BY company
HAVING COUNT(*) >= 100
ORDER BY complaints DESC
LIMIT 15;
