select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    a.total_amount
from {{ ref('stg_orders') }} o
left join {{ ref('int_order_amounts') }} a
    on o.order_id = a.order_id
