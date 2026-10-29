-- Fails if any computed rate falls outside 0-100.
select company, monetary_relief_pct, timely_pct
from {{ ref('mart_company_outcomes') }}
where monetary_relief_pct not between 0 and 100
   or non_monetary_relief_pct not between 0 and 100
   or timely_pct not between 0 and 100
