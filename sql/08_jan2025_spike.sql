-- Q8: What drove the January 2025 spike seen in Q6?
-- Compares each company's January 2025 count to its average month in 2024,
-- using a CTE per side and a JOIN. NULLIF avoids dividing by zero.
WITH jan25 AS (
    SELECT company, COUNT(*) AS jan_2025
    FROM complaints
    WHERE strftime('%Y-%m', date_received) = '2025-01'
    GROUP BY company
),
avg24 AS (
    SELECT company, COUNT(*) / 12.0 AS avg_month_2024
    FROM complaints
    WHERE strftime('%Y', date_received) = '2024'
    GROUP BY company
)
SELECT j.company,
       j.jan_2025,
       ROUND(a.avg_month_2024, 1)                          AS avg_month_2024,
       ROUND(j.jan_2025 / NULLIF(a.avg_month_2024, 0), 1)  AS x_typical_month
FROM jan25 j
LEFT JOIN avg24 a ON a.company = j.company   -- LEFT JOIN: keep companies that had no 2024 complaints
ORDER BY j.jan_2025 - COALESCE(a.avg_month_2024, 0) DESC
LIMIT 5;
