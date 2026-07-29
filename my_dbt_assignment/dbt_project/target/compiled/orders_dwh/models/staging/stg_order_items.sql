-- Staging model for raw order items: casts price/quantity to numeric types and drops rows missing id or order_id.
select
    id,
    order_id,
    product_id,
    cast(price as decimal(18, 2)) as price,
    cast(quantity as int) as quantity
from analytics.raw_order_items
where id is not null
  and order_id is not null