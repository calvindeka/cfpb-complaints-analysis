-- Q12 (spike check 4/4): Are received / sent-to-company dates consistent for the spike?
-- If a batch upload had mis-stamped dates, the gap (date_sent - date_received) would look odd:
-- negative, or very long. Compare Navy Jan 2025 with Navy in the rest of the data.
-- julianday() turns 'YYYY-MM-DD' into a number so we can subtract.
SELECT CASE WHEN date_received LIKE '2025-01%' THEN 'Navy Jan 2025' ELSE 'Navy other months' END AS grp,
       COUNT(*)                                                                   AS complaints,
       ROUND(AVG(julianday(date_sent) - julianday(date_received)), 2)             AS avg_days_to_company,
       MAX(julianday(date_sent) - julianday(date_received))                       AS max_days,
       SUM(julianday(date_sent) < julianday(date_received))                       AS sent_before_received,
       ROUND(100.0 * SUM(timely_response) / COUNT(*), 2)                          AS pct_timely
FROM complaints
WHERE company LIKE 'NAVY FEDERAL%'
GROUP BY grp;
