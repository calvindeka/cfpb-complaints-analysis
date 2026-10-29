-- Fails if the monthly mart does not add back up to every complaint.
select sum(complaints) as mart_total
from {{ ref('mart_monthly_product') }}
having sum(complaints) != (select count(*) from {{ ref('fct_complaints') }})
