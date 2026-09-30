-- Q11 (spike check 3/4): Does Navy Federal's January 2025 excess sit in one product / issue /
-- state / channel? Each dimension is compared to Navy's average month in 2024.
-- UNION ALL stacks the four breakdowns into one result (same columns each time).
-- avg_month_2024 = 2024 count / 12, so x_typical > 1 means "more than a typical month".
WITH navy AS (
    SELECT * FROM complaints WHERE company LIKE 'NAVY FEDERAL%'
),
breakdown AS (
    SELECT 'product' AS dim, product AS value, date_received, 1 AS n FROM navy
    UNION ALL SELECT 'issue', issue, date_received, 1 FROM navy
    UNION ALL SELECT 'state', COALESCE(state, '(none)'), date_received, 1 FROM navy
    UNION ALL SELECT 'channel', submitted_via, date_received, 1 FROM navy
)
SELECT dim, value,
       SUM(CASE WHEN date_received LIKE '2025-01%' THEN n ELSE 0 END)              AS jan_2025,
       ROUND(SUM(CASE WHEN date_received LIKE '2024-%' THEN n ELSE 0 END) / 12.0, 1) AS avg_month_2024,
       ROUND(SUM(CASE WHEN date_received LIKE '2025-01%' THEN n ELSE 0 END)
             / NULLIF(SUM(CASE WHEN date_received LIKE '2024-%' THEN n ELSE 0 END) / 12.0, 0), 1) AS x_typical
FROM breakdown
GROUP BY dim, value
HAVING jan_2025 >= 100          -- ignore tiny categories
ORDER BY dim, jan_2025 DESC;
