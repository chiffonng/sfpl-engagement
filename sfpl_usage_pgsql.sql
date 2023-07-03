CREATE OR REPLACE FUNCTION return_clean_data() 
LANGUAGE PLPGSQL
AS $$
    -- Create database if not exists
    CREATE DATABASE IF NOT EXISTS sfpl_usage;
    
    -- Switch to the newly created database
    \c sfpl_usage;
    
    -- Create a temporary table to read the CSV file
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
    -- Set up a transaction
    BEGIN;
    -- Convert month name to number (1-12), still type varchar
    UPDATE tbl_library_usage
    SET circulation_active_month = 
        CASE circulation_active_month
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
    COMMIT:

    -- Cast varchar to int
    ALTER TABLE tbl_library_usage
    ALTER COLUMN 
        circulation_active_year TYPE INTEGER 
        USING (circulation_active_year::INT) 
        circulation_active_month TYPE INTEGER 
        USING COALESCE(circulation_active_month, 0)::INT
    -- Create new column to combine year and month
    ADD COLUMN last_active DATE;

    BEGIN;
    UPDATE tbl_library_usage
    SET last_active = MAKE_DATE(
            circulation_active_year::INT,
            COALESCE(circulation_active_month, '0')::INT,
            1
        )
    WHERE circulation_active_year IS NOT NULL;
    COMMIT;

$$;

/* ================== VIEWS ================= */

-- Distribution of patrons by age range
CREATE VIEW vw_patron_by_age_range AS
    SELECT age_range,
        COUNT(*) AS patron_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS patron_percentage
    FROM tbl_library_usage
    GROUP BY age_range;
-- Invoke the view
SELECT * FROM vw_patron_by_age_range;

-- Summary statistics by patron types
CREATE VIEW vw_patron_type AS
    SELECT patron_type,
        COUNT(*) AS patron_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS patron_percentage,
        ROUND(AVG(checkouts_total), 2) AS avg_checkouts,
        ROUND(AVG(renewals_total), 2) AS avg_renewals
    FROM tbl_library_usage
    GROUP BY patron_type
    ORDER BY patron_type;
-- Invoke the view
SELECT * FROM vw_patron_type;

-- Summary statistics by library branch
CREATE VIEW vw_library_branch AS
    SELECT library_branch,
        COUNT(*) AS patron_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS patron_percentage,
        ROUND(AVG(checkouts_total), 2) AS avg_checkouts,
        ROUND(AVG(renewals_total), 2) AS avg_renewals
    FROM tbl_library_usage
    GROUP BY library_branch
    ORDER BY patron_count DESC;
-- Invoke the view
SELECT * FROM vw_library_branch;