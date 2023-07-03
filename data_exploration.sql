\i clean_data.sql
/* ================== VIEWS ================= */
-- Distribution of patrons by age range
CREATE VIEW vw_patron_by_age_range AS
SELECT age_range,
    COUNT(*) AS patron_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS patron_percentage
FROM tbl_library_usage
GROUP BY age_range;
-- Invoke the view
SELECT *
FROM vw_patron_by_age_range;

-- Summary statistics by patron types
CREATE OR REPLACE VIEW vw_patron_type AS
SELECT patron_type,
    COUNT(*) AS patron_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS patron_percentage,
    ROUND(AVG(checkouts_total), 2) AS avg_checkouts,
    ROUND(AVG(renewals_total), 2) AS avg_renewals
FROM tbl_library_usage
GROUP BY patron_type
ORDER BY patron_type;
-- Invoke the view
SELECT *
FROM vw_patron_type;

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
SELECT *
FROM vw_library_branch;

/* ================== QUERIES ================= */
-- Top x library branches with the highest number of patrons 
-- with x obtained from user input

CREATE OR REPLACE FUNCTION get_top_library_branches(x INT) RETURNS TABLE (
        library_branch VARCHAR(30),
        patron_count INT,
        avg_checkouts NUMERIC,
        avg_renewals NUMERIC
    ) AS $$ 
    SELECT library_branch,
        patron_count,
        avg_checkouts,
        avg_renewals
    FROM vw_library_branch
    ORDER BY patron_count DESC
    LIMIT x;
$$ LANGUAGE SQL;
SELECT * FROM get_top_library_branches(5);

-- How many new patrons registered each year?
CREATE OR REPLACE FUNCTION get_registrations_by_year() RETURNS TABLE (
        registration_year INT,
        new_patrons INT
    ) AS $$
    SELECT registration_year,
        COUNT(*) AS new_patrons
    FROM tbl_library_usage
    WHERE registration_year IS NOT NULL
    GROUP BY registration_year
    ORDER BY registration_year;
$$ LANGUAGE SQL;
SELECT * FROM get_registrations_by_year();

-- Get patrons that are not active in the last x months
CREATE OR REPLACE FUNCTION get_inactive_patrons(x INT) RETURNS TABLE (

    ) AS $$
    SELECT patron_type,
        patron_count,
        patron_percentage,
        avg_checkouts,
        avg_renewals
    FROM vw_patron_type
    WHERE patron_type IN (
        SELECT patron_type
        FROM tbl_library_usage
        WHERE last_active < CURRENT_DATE - INTERVAL '1 month' * x
    );
$$ LANGUAGE SQL;