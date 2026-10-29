-- Daily volume for Dec 2024 - Feb 2025, top companies split out, to show
-- the January 2025 surge rising and decaying over several days.
select
    date_received,
    case when company in ('NAVY FEDERAL CREDIT UNION', 'CAPITAL ONE FINANCIAL CORPORATION')
         then company else 'All other companies' end               as company_group,
    count(*)                                                        as complaints
from {{ ref('fct_complaints') }}
where date_received between date '2024-12-01' and date '2025-02-28'
group by 1, 2
