--
-- Copyright (c) 2023 Oracle
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions -- of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--
-- NAME
--   hr_create.sql - Creates schema objects for HR (Human Resources) schema
--
-- DESCRIPTON
--   This script creates tables, associated constraints,
--      indexes, and comments in the HR schema.
--
-- SCHEMA VERSION
--   21
--
-- RELEASE DATE
--   03-FEB-2022
--
-- SUPPORTED with DB VERSIONS
--   19c and higher
-- 
-- MAJOR CHANGES IN THIS RELEASE
-- ---------------------------------------------------------------------

-- ********************************************************************
DO $$
BEGIN
  RAISE NOTICE '****** Print the current database and user name....';
  RAISE NOTICE 'Current Database: %', current_database();
  RAISE NOTICE 'Current User: %', current_user;
END $$;

-- ********************************************************************
-- Create the REGIONS table to hold region information for locations
-- HR.LOCATIONS table has a foreign key to this table.

CREATE TABLE regions ( region_id INT CONSTRAINT  region_id_nn NOT NULL, region_name VARCHAR(25) );
-- Creating a UNIQUE INDEX is not technically required as the PRIMARY KEY constraint creates a unique index automatically.
CREATE UNIQUE INDEX reg_id_pk ON regions (region_id);
ALTER TABLE regions ADD CONSTRAINT reg_id_pk PRIMARY KEY USING INDEX reg_id_pk;

-- ********************************************************************
-- Create the COUNTRIES table to hold country information for customers
-- and company locations.
-- OE.CUSTOMERS table and HR.LOCATIONS have a foreign key to this table.

CREATE TABLE countries ( country_id CHAR(2) CONSTRAINT country_id_nn NOT NULL, country_name VARCHAR(60), region_id INT );
ALTER TABLE countries ADD CONSTRAINT country_id_pk PRIMARY KEY (country_id);
ALTER TABLE countries ADD CONSTRAINT country_region_fk FOREIGN KEY (region_id) REFERENCES regions(region_id);

-- ********************************************************************
-- Create the LOCATIONS table to hold address information for company departments.
-- HR.DEPARTMENTS has a foreign key to this table.

CREATE TABLE locations( 
  location_id INT NOT NULL, 
  street_address VARCHAR(40), 
  postal_code VARCHAR(12), 
  city VARCHAR(30) NOT NULL, 
  state_province VARCHAR(25), 
  country_id CHAR(2) 
);

ALTER TABLE locations ADD CONSTRAINT loc_id_pk PRIMARY KEY (location_id);
CREATE UNIQUE INDEX loc_id_index ON locations (location_id);

-- ********************************************************************
-- Create the DEPARTMENTS table to hold company department information.
-- HR.EMPLOYEES and HR.JOB_HISTORY have a foreign key to this table.

CREATE TABLE departments
    ( department_id    INT NOT NULL
    , department_name  VARCHAR(30) CONSTRAINT dept_name_nn  NOT NULL
    , manager_id       INT
    , location_id      INT
    );
ALTER TABLE departments ADD CONSTRAINT dept_id_pk PRIMARY KEY (department_id);
CREATE UNIQUE INDEX dept_id_index ON departments (department_id);
ALTER TABLE departments ADD CONSTRAINT dept_loc_fk FOREIGN KEY (location_id) REFERENCES locations (location_id);

-- ********************************************************************
-- Create the JOBS table to hold the different names of job roles within the company.
-- HR.EMPLOYEES has a foreign key to this table.

CREATE TABLE jobs
    ( job_id VARCHAR(10) NOT NULL
    , job_title      VARCHAR(35) CONSTRAINT job_title_nn  NOT NULL
    , min_salary     DECIMAL(6)
    , max_salary     DECIMAL(6)
    );

ALTER TABLE jobs ADD CONSTRAINT job_id_pk PRIMARY KEY (job_id);
CREATE UNIQUE INDEX job_id_index ON jobs (job_id);

-- ********************************************************************
-- Create the EMPLOYEES table to hold employee information.

CREATE TABLE employees
    ( employee_id    INT NOT NULL
    , first_name     VARCHAR(20)
    , last_name      VARCHAR(25) CONSTRAINT emp_last_name_nn NOT NULL
    , email          VARCHAR(25) CONSTRAINT emp_email_nn NOT NULL
    , phone_number   VARCHAR(20)
    , hire_date      TIMESTAMP CONSTRAINT emp_hire_date_nn NOT NULL
    , job_id         VARCHAR(10) CONSTRAINT emp_job_nn NOT NULL
    , salary         DECIMAL(8,2)
    , commission_pct DECIMAL(2,2)
    , manager_id     INT
    , department_id  INT
    , CONSTRAINT     emp_salary_min CHECK (salary > 0) 
    , CONSTRAINT     emp_email_uk UNIQUE (email)
    );

-- CREATE UNIQUE INDEX emp_emp_id_index ON employees (employee_id);

ALTER TABLE employees 
ADD CONSTRAINT emp_emp_id_pk PRIMARY KEY (employee_id);

ALTER TABLE employees 
ADD CONSTRAINT emp_dept_fk FOREIGN KEY (department_id) REFERENCES departments(department_id);

ALTER TABLE employees
ADD CONSTRAINT emp_job_fk FOREIGN KEY (job_id) REFERENCES jobs(job_id);

ALTER TABLE employees
ADD CONSTRAINT emp_manager_fk FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

ALTER TABLE departments
ADD CONSTRAINT dept_mgr_fk FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

-- ********************************************************************
-- Create the JOB_HISTORY table to hold the job history of employees.
-- Create the JOB_HISTORY table

CREATE TABLE job_history
    ( employee_id   INT         CONSTRAINT    jhist_employee_nn   NOT NULL
    , start_date    TIMESTAMP   CONSTRAINT    jhist_start_date_nn NOT NULL
    , end_date      TIMESTAMP   CONSTRAINT    jhist_end_date_nn   NOT NULL
    , job_id        VARCHAR(10) CONSTRAINT    jhist_job_nn        NOT NULL
    , department_id INT
    , CONSTRAINT    jhist_date_interval CHECK (end_date > start_date)
    );

-- Create a unique index on the employee_id and start_date columns
CREATE UNIQUE INDEX jhist_emp_id_st_date_index ON job_history (employee_id, start_date);

ALTER TABLE job_history
ADD CONSTRAINT jhist_emp_id_st_date_pk PRIMARY KEY (employee_id, start_date);

ALTER TABLE job_history
ADD CONSTRAINT jhist_job_fk FOREIGN KEY (job_id) REFERENCES jobs(job_id);

ALTER TABLE job_history
ADD CONSTRAINT jhist_emp_fk FOREIGN KEY (employee_id) REFERENCES employees(employee_id);

ALTER TABLE job_history
ADD CONSTRAINT jhist_dept_fk FOREIGN KEY (department_id) REFERENCES departments(department_id);

-- ********************************************************************
-- Create the EMP_DETAILS_VIEW view to display employee information
-- from the EMPLOYEES, DEPARTMENTS, and JOBS tables.
--

-- IF OBJECT_ID('emp_details_view', 'V') IS NOT NULL DROP VIEW emp_details_view;

-- CREATE VIEW emp_details_view
--   AS SELECT
--   e.employee_id, 
--   e.job_id, 
--   e.manager_id, 
--   e.department_id,
--   d.location_id,
--   l.country_id,
--   e.first_name,
--   e.last_name,
--   e.salary,
--   e.commission_pct,
--   d.department_name,
--   j.job_title,
--   l.city,
--   l.state_province,
--   c.country_name,
--   r.region_name
-- FROM
--   employees e
-- JOIN departments d ON e.department_id = d.department_id
-- JOIN jobs j ON j.job_id = e.job_id 
-- JOIN locations l ON d.location_id = l.location_id
-- JOIN countries c ON l.country_id = c.country_id
-- JOIN regions r ON c.region_id = r.region_id;

-- ********************************************************************
-- Create the EMP_DETAILS_VIEW view to display employee information
-- from the EMPLOYEES, DEPARTMENTS, and JOBS tables.
--

-- CREATE INDEX emp_department_ix ON employees (department_id);
-- CREATE INDEX emp_job_ix ON employees (job_id);
-- CREATE INDEX emp_manager_ix ON employees (manager_id);
-- CREATE INDEX emp_name_ix ON employees (last_name, first_name);
-- CREATE INDEX dept_location_ix ON departments (location_id);
-- CREATE INDEX jhist_job_ix ON job_history (job_id);
-- CREATE INDEX jhist_employee_ix ON job_history (employee_id);
-- CREATE INDEX jhist_department_ix ON job_history (department_id);
-- CREATE INDEX loc_city_ix ON locations (city);
-- CREATE INDEX loc_state_province_ix ON locations (state_province);
-- CREATE INDEX loc_country_ix ON locations (country_id);

-- ********************************************************************
-- Add table column comments
--

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Regions table that contains region numbers and names. references with the Countries table.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'regions';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Primary key of regions table.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'regions', 
-- @level2type = N'COLUMN', @level2name = 'region_id';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Names of regions. Locations are in the countries of these regions.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'regions', 
-- @level2type = N'COLUMN', @level2name = 'region_name';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Locations table that contains specific address of a specific office, warehouse, and/or production site of a company. Does not store addresses / locations of customers. references with the departments and countries tables.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'locations';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Departments table that shows details of departments where employees work. references with locations, employees, and job_history tables.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'departments';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Primary key column of departments table.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'departments', 
-- @level2type = N'COLUMN', @level2name = 'department_id';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'A not null column that shows name of a department. Administration, Marketing, Purchasing, Human Resources, Shipping, IT, Executive, Public Relations, Sales, Finance, and Accounting.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'departments', 
-- @level2type = N'COLUMN', @level2name = 'department_name';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Manager_id of a department. Foreign key to employee_id column of employees table. The manager_id column of the employee table references this column.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'departments', 
-- @level2type = N'COLUMN', @level2name = 'manager_id';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Location id where a department is located. Foreign key to location_id column of locations table.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'departments', 
-- @level2type = N'COLUMN', @level2name = 'location_id';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Table that stores job history of the employees. If an employee changes departments within the job or changes jobs within the department, new rows get inserted into this table with old job information of the employee. Contains a complex primary key: employee_id+start_date. References with jobs, employees, and departments tables.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'job_history';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'A not null column in the complex primary key employee_id+start_date. Foreign key to employee_id column of the employee table', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'job_history', 
-- @level2type = N'COLUMN', @level2name = 'employee_id';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'A not null column in the complex primary key employee_id+start_date. Must be less than the end_date of the job_history table. (enforced by constraint jhist_date_interval)', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'job_history', 
-- @level2type = N'COLUMN', @level2name = 'start_date';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Last day of the employee in this job role. A not null column. Must be greater than the start_date of the job_history table. (enforced by constraint jhist_date_interval)', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'job_history', 
-- @level2type = N'COLUMN', @level2name = 'end_date';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Job role in which the employee worked in the past; foreign key to job_id column in the jobs table. A not null column.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'job_history', 
-- @level2type = N'COLUMN', @level2name = 'job_id';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'Department id in which the employee worked in the past; foreign key to deparment_id column in the departments table', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'job_history', 
-- @level2type = N'COLUMN', @level2name = 'department_id';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'country table. References with locations table.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'countries';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'jobs table with job titles and salary ranges. References with employees and job_history table.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'jobs';

-- EXEC sp_addextendedproperty 
-- @name = N'MS_Description', 
-- @value = 'employees table. References with departments, jobs, job_history tables. Contains a self reference.', 
-- @level0type = N'SCHEMA', @level0name = 'dbo', 
-- @level1type = N'TABLE',  @level1name = 'employees';