CREATE PROC sfpl_management AS 
CREATE DATABASE IF NOT EXISTS sfpl_usage;
GO
    /* ============ TABLE ============ */
    CREATE TABLE IF NOT EXISTS tbl_library_usage(
        patron_type_code INT NOT NULL,
        patron_type VARCHAR(30) NOT NULL,
        checkouts_total INT NOT NULL,
        renewals_total INT NOT NULL,
        age_range VARCHAR(30),
        registration_year INT,
        library_code VARCHAR(10),
        library_branch VARCHAR(30),
        circulation_active_month VARCHAR(10),
        circulation_active_year VARCHAR(10),
        notification_medium_code VARCHAR(10),
        notification_medium VARCHAR(20),
        email_notification BOOLEAN NOT NULL,
        isin_sf BOOLEAN NOT NULL
    );
    -- Ingest CSV file
    COPY tbl_library_usage
    FROM 'sfpl_usage.csv' DELIMITER ',' CSV HEADER;

/* ============ CLEANING ============ */
-- Delete null values
DELETE FROM tbl_library_usage
WHERE circulation_active_month IS NULL
    OR circulation_active_year IS NULL;
-- Cast varchar to int
UPDATE tbl_library_usage
SET circulation_active_year = circulation_active_year::INT
SET circulation_active_month = circulation_active_month::INT;
-- Create new column for last active
ALTER TABLE tbl_library_usage
ALTER COLUMN 
    circulation_active_year TYPE INTEGER USING (circulation_active_year::INT) 
    circulation_active_month TYPE INTEGER USING (circulation_active_month::INT)
ADD COLUMN last_active DATE;
UPDATE tbl_library_usage
SET last_active = MAKE_DATE(
        circulation_active_year,
        circulation_active_month,
        1
    );

/* ================== VIEWS ================= */

-- Distribution of patrons by age range
CREATE VIEW vw_patron_by_age_range AS
    SELECT age_range,
        COUNT(*) AS patron_count,
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS patron_percentage
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
    GROUP BY patron_type;
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