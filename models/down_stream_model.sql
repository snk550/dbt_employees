

with cte as (

    select employee_number,first_name,last_name
    from {{ ref('employee_current_view')}}
    limit 10

)

select * from cte