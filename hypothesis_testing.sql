-- View: public.vw_less_active_patrons

DROP MATERIALIZED VIEW IF EXISTS vw_less_active_patrons;

CREATE MATERIALIZED VIEW vw_less_active_patrons AS
	SELECT id,
		patron_type,
		age_range,
		library_branch,
		is_address_in_sf,
		notice_medium,
		last_active
	FROM tbl_library_usage
	WHERE last_active < DATE('2023-01-01') - INTERVAL '12 mons';

-- Factor 1: Physical address 
SELECT is_address_in_sf, 
	COUNT(*) AS patron_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS patron_percentage
FROM vw_less_active_patrons
GROUP BY 1
ORDER BY 2 DESC;

SELECT notice_medium, 
	COUNT(*) AS patron_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS patron_percentage
FROM vw_less_active_patrons
WHERE is_address_in_sf = FALSE
GROUP BY 1
ORDER BY 2 DESC;

-- Factor 2: Age range
WITH grouped_age_range AS (
	SELECT age_range,
		COUNT(*) AS patron_count
	FROM tbl_library_usage
	GROUP BY 1
), 
less_active_age_range AS (
	SELECT age_range, 
		COUNT(*) AS patron_count
	FROM vw_less_active_patrons
	GROUP BY 1)

SELECT filtered.age_range, 
	filtered.patron_count AS patron_count,
	ROUND(filtered.patron_count::numeric / original.patron_count * 100.0,1) AS patron_percentage
FROM grouped_age_range AS original
JOIN less_active_age_range AS filtered
	USING(age_range)
ORDER BY patron_percentage DESC;

-- Factor 2 (continued): Patron type
WITH grouped_patron_type AS (
	SELECT patron_type,
		COUNT(*) AS patron_count
	FROM tbl_library_usage
	GROUP BY 1
), 
less_active_patron_type AS (
	SELECT patron_type, 
		COUNT(*) AS patron_count
	FROM vw_less_active_patrons
	GROUP BY 1)

SELECT filtered.patron_type, 
	filtered.patron_count AS patron_count,
	ROUND(filtered.patron_count::numeric / original.patron_count * 100.0,1) AS patron_percentage
FROM grouped_patron_type AS original
JOIN less_active_patron_type AS filtered
	USING(patron_type)
ORDER BY patron_count DESC;