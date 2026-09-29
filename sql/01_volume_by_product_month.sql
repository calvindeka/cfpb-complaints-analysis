-- Q1: How many complaints per product per month?
-- strftime('%Y-%m', ...) cuts 'YYYY-MM-DD' down to 'YYYY-MM' so GROUP BY can bucket by month.
SELECT strftime('%Y-%m', date_received) AS month,
       product,
       COUNT(*)                         AS complaints
FROM complaints
GROUP BY month, product
ORDER BY month, product;
