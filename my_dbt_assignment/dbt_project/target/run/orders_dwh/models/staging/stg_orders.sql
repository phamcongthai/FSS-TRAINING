create or replace view analytics.stg_orders
  
  
  as
    -- Staging model for raw orders: casts order_date to DATE and drops rows with a missing order_id.
select
    order_id,
    customer_id,
    cast(order_date as date) as order_date,
    status
from analytics.raw_orders
where order_id is not null
