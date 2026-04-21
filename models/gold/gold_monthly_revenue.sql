{{ config(database='workspace') }}

with order_line_revenue as (
  select
    o.order_id,
    date_trunc('month', o.order_date) as order_month,
    o.order_status_label,
    sum(l.revenue) as order_revenue
  from {{ workspace_ref('silver_orders') }} as o
  inner join {{ workspace_ref('silver_lineitem') }} as l
    on o.order_id = l.order_id
  group by
    o.order_id,
    date_trunc('month', o.order_date),
    o.order_status_label
)

select
  order_month,
  order_status_label,
  count(distinct order_id) as order_count,
  sum(order_revenue) as total_revenue,
  avg(order_revenue) as avg_order_value
from order_line_revenue
group by
  order_month,
  order_status_label
order by
  order_month asc,
  order_status_label asc
