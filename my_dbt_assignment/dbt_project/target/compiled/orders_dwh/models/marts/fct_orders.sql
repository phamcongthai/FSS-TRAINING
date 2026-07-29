select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    a.total_amount
from analytics.stg_orders o
left join analytics.int_order_amounts a
    on o.order_id = a.order_id