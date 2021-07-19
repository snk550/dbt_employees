/* Build a view that lists current employees */
select employee_number, first_name, last_name, email, phone_number, snapshot_date current_as_of
from hr.dim_employee
where snapshot_date = (select max(snapshot_date) from hr.dim_employee)