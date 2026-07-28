-- Staging model for raw orders: casts order_date to DATE and drops rows with a missing order_id.
select
    order_id,
    customer_id,
    cast(order_date as date) as order_date,
    status
from {{ ref('raw_orders') }}
where order_id is not null
