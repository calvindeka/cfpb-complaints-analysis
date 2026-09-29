-- Q7: Days between CFPB receiving a complaint and forwarding it to the company.
-- NOT the company's response time (that date is not in this dataset).
-- julianday() turns a date into a number so we can subtract.
SELECT product,
       COUNT(*)                                                             AS complaints,
       ROUND(AVG(julianday(date_sent) - julianday(date_received)), 2)       AS avg_days,
       MAX(julianday(date_sent) - julianday(date_received))                 AS max_days,
       SUM(julianday(date_sent) < julianday(date_received))                 AS sent_before_received
FROM complaints
GROUP BY product
ORDER BY product;
