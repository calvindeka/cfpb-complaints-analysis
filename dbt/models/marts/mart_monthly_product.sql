-- Monthly volume per product with month-over-month change (window function).
with monthly as (
    select
        month_received,
        product,
        count(*)                as complaints,
        sum(is_monetary_relief) as monetary_relief
    from {{ ref('fct_complaints') }}
    group by month_received, product
)

select
    month_received,
    product,
    complaints,
    monetary_relief,
    lag(complaints) over (partition by product order by month_received) as prev_month_complaints,
    round(100.0 * (complaints - lag(complaints) over (partition by product order by month_received))
          / nullif(lag(complaints) over (partition by product order by month_received), 0), 1) as mom_change_pct
from monthly
