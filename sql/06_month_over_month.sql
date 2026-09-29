-- Q6: Month-over-month change in total complaints.
-- LAG(x) looks at the previous row (previous month) in the ORDER BY.
WITH monthly AS (
    SELECT strftime('%Y-%m', date_received) AS month, COUNT(*) AS complaints
    FROM complaints
    GROUP BY month
)
SELECT month,
       complaints,
       LAG(complaints) OVER (ORDER BY month)                                   AS prev_month,
       ROUND(100.0 * (complaints - LAG(complaints) OVER (ORDER BY month))
             / LAG(complaints) OVER (ORDER BY month), 1)                       AS pct_change
FROM monthly
ORDER BY month;
