-- Use the INFORMATION_SCHEMA.COLUMNS view to get general information about columns
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'employees';


-- Use the INFORMATION_SCHEMA.TABLES view to get general information about tables
SELECT 
    CONSTRAINT_NAME, 
    TABLE_NAME, 
    CONSTRAINT_TYPE 
FROM 
    INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE 
    TABLE_NAME = 'employees';

-- Return an arbitruary value once only
SELECT 'henry'
SELECT CURRENT_TIMESTAMP AS "time";

-- Returned output can contain columns that are created within the query
SELECT employee_id, employee_id + salary AS test, salary AS new_salary, salary FROM employees;

-- The row-based (only one per query) DISTINCT keyword can be used to return only values which are unique in combination
SELECT distinct job_id, department_id FROM employees;

-- Concatenate strings with the || operator (contatinating Null values does NOT result in Null, it results in non-null value)
SELECT 'my name is ' || first_name as name FROM employees;

-- arithmetic against a NULL value results in NULL
SELECT salary, salary*commission_pct, commission_pct FROM employees;

-- When using the WHERE clause, remember to use quotes around strings
SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME FROM EMPLOYEES WHERE job_id = 'SA_MAN'