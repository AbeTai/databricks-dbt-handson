{{ config(database='workspace') }}

select
  o_orderkey as order_id,
  o_custkey as customer_id,
  o_orderstatus as order_status,
  case o_orderstatus
    when 'O' then 'Open'
    when 'F' then 'Fulfilled'
    when 'P' then 'Pending'
    else 'Unknown'
  end as order_status_label,
  o_totalprice as total_price,
  cast(o_orderdate as date) as order_date,
  o_orderpriority as order_priority,
  o_shippriority as ship_priority
from {{ workspace_ref('bronze_orders') }}
