-- Fails if the CFPB forwarded a complaint before it received it.
select complaint_id, days_to_company
from {{ ref('stg_complaints') }}
where days_to_company < 0
