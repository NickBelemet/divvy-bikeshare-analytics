/*
 Divvy Bikeshare Analysis (2016–2019)
 PostgreSQL | Portfolio version
 Extracted from the complete project script for easier GitHub navigation.
*/

-- SECTION 1: DATASET EXPLORATION 
-- ====================================================================

-- 1.1 Inspecting table structure/data 

SELECT *
FROM divvybikes_2019
LIMIT 10; 

SELECT * 
FROM divvy_stations; 

-- 1.2 Column name and data types 

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN (
    'divvybikes_2016',
    'divvybikes_2017',
    'divvybikes_2018',
    'divvybikes_2019'
)
ORDER BY table_name, ordinal_position;

-- 1.3 Count records by year 

SELECT '2016' AS year, COUNT(*) AS total_trips
FROM divvybikes_2016
UNION ALL

SELECT '2017', COUNT(*)
FROM divvybikes_2017
UNION ALL

SELECT '2018', COUNT(*)
FROM divvybikes_2018
UNION ALL

SELECT '2019', COUNT(*)
FROM divvybikes_2019
ORDER BY year;

-- ====================================================================
