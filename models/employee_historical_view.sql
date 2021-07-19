/*Build a historical table that tracks employee salary and tenure and other descriptive attributes over time*/

with cte as  ( 
    -- band salary ranges for easier analysis and mark when there is a break in connsecutive employment dates
    -- i.e. indicate when an employee leaves the company but the same employee returns
    select *,
    case 
    when salary < 50000 then '< 50000'
    when salary between 50000 and 74999 then '50000-74999'
    when salary between 75000 and 99999 then '75000-99999'
    when salary between 100000 and 124999 then '100000-124999'
    else '> 125000' end salary_band,
    case 
    when date_part('day', snapshot_date - lag(snapshot_date) over(partition by employee_number order by snapshot_date)) > 1 
    then 1 else 0 end grp
    from hr.dim_employee

), cte2 as (
    -- cumulative sum to establish seperate periods of for the same employee
    -- i.e. John Doe is a contractor and was employed between Jan 1 and Mar 31 and Jul 1 Sept 30
    select *,
    sum(grp) over(partition by employee_number order by snapshot_date) tenure_grp
    from cte

), cte3 as (
    -- detect changes in salary bands or if the employee leaves the company and comes back
    select
    employee_number,salary_band,min(snapshot_date) start_date, 
    case  
    when max(snapshot_date) != (select max(snapshot_date) from hr.dim_employee)
    then max(snapshot_date) else null end end_date
    from cte2
    group by employee_number,salary_band,tenure_grp
    order by employee_number

)
-- finally add descriptive attributes name, gender, etc.
select a.employee_number, first_name, last_name, gender, salary_band, start_date, end_date
from cte3 a
left join ( 
    select *
    from (
        select 
        employee_number,first_name,last_name,gender,
        row_number() over(partition by employee_number order by snapshot_date desc) rn
        from hr.dim_employee
    ) ranking
    where rn = 1
) b
on a.employee_number = b.employee_number