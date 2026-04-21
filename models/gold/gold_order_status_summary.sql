{{ config(database='workspace') }}

with status_summary as (
  select
    order_status_label,
    count(*) as order_count,
    sum(total_price) as total_price,
    avg(total_price) as avg_price
  from {{ workspace_ref('silver_orders') }}
  group by order_status_label
)

select
  order_status_label,
  order_count,
  total_price,
  avg_price,
  order_count / sum(order_count) over () * 100 as pct_of_total
from status_summary
order by order_count desc
