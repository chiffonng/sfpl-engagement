CREATE OR REPLACE PROCEDURE return_clean_data() LANGUAGE SQL AS $$ 
-- Create database if not exists
    CREATE DATABASE IF NOT EXISTS sfpl_usage;
-- Switch to the newly created database
\ c sfpl_usage;
-- Create a table to read the CSV file
CREATE TABLE tbl_library_usage (
    patron_type_code INT NOT NULL,
    patron_type VARCHAR(30) NOT NULL,
    checkouts_total INT NOT NULL,
    renewals_total INT NOT NULL,
    age_range VARCHAR(30),
    library_code VARCHAR(10),
    library_branch VARCHAR(30),
    circulation_active_month VARCHAR(10),
    circulation_active_year VARCHAR(10),
    notice_medium_code VARCHAR(10),
    notice_medium VARCHAR(20),
    has_email BOOLEAN NOT NULL,
    registration_year INT,
    is_address_in_sf BOOLEAN NOT NULL
);
-- Ingest or replace CSV file
COPY tbl_library_usage
FROM 'sfpl_usage.csv' DELIMITER ',' CSV HEADER;
/* ============ CLEANING ============ */
-- Set up a transaction, in case we want a rollback
BEGIN;
-- Convert month name to number (1-12), still type varchar
UPDATE tbl_library_usage
SET circulation_active_month = CASE
        circulation_active_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
        ELSE 0 -- for null values
    END;
COMMIT;
-- Cast varchar to int
ALTER TABLE tbl_library_usage
ALTER COLUMN circulation_active_year TYPE INTEGER USING (circulation_active_year::INT) circulation_active_month TYPE INTEGER USING COALESCE(circulation_active_month, 0)::INT
ADD COLUMN id SERIAL PRIMARY KEY
ADD COLUMN last_active DATE;
-- Create new date column to combine year and month
BEGIN;
-- Using 20 every month as a default date
UPDATE tbl_library_usage
SET last_active = MAKE_DATE(
        circulation_active_year,
        circulation_active_month,
        20
    )
WHERE circulation_active_year IS NOT NULL;
COMMIT;
$$;
CALL return_clean_data();