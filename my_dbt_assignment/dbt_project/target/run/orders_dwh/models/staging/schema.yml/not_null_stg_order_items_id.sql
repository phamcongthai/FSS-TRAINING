
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id
from analytics.stg_order_items
where id is null



  
  
      
    ) dbt_internal_test