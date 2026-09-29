-- Q4: Share of complaints where the company responded on time, by product.
-- timely_response is stored 0/1, so SUM/COUNT is the rate.
SELECT product,
       COUNT(*)                                            AS complaints,
       SUM(timely_response)                                AS timely,
       ROUND(100.0 * SUM(timely_response) / COUNT(*), 2)   AS pct_timely
FROM complaints
GROUP BY product
ORDER BY pct_timely;
