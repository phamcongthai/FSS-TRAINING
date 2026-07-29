-- Materialization choice: 'view' vs 'ephemeral'
-- Chosen 'view' (not 'ephemeral') so this model can be queried directly in
-- Spark for debugging/inspection and appears as its own node in dbt docs
-- lineage with its own compiled object, instead of being inlined as a CTE
-- inside fct_orders. Spark views are cheap to compute, so favoring
-- inspectability over hiding the intermediate logic is the better trade-off
-- for this assignment.


select
    order_id,
    sum(total_item_price) as total_amount
from (
    select
        order_id,
        price * quantity as total_item_price
    from analytics.stg_order_items
) item_totals
group by order_id