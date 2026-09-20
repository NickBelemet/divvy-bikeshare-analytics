/*
 Divvy Bikeshare Analysis (2016–2019)
 PostgreSQL | Portfolio version
 Extracted from the complete project script for easier GitHub navigation.
*/

-- SECTION 3: FINAL CLEANING & TRANSFORMATION LOGIC
-- ====================================================================
/*
Purpose
-------
Create a reproducible, read-only cleaning pipeline for the Tableau extracts.
No source tables are modified. All transformations are performed with CTEs.

Important final rule
--------------------
The Tableau extracts currently used in the workbook were built with a maximum
valid trip duration of 240 minutes (4 hours). This reproduces the submitted
Tableau totals. The earlier data-quality investigation first flagged journeys
above 24 hours; the stricter 4-hour analytical threshold was adopted only after
reviewing the long right tail and is therefore documented here explicitly.

If the intended final policy is instead to retain all positive trips up to
24 hours, change max_valid_duration_minutes from 240.0 to 1440.0 and rebuild
both Tableau extracts so the SQL and workbook remain consistent.

Other final rules
-----------------
1. Remove only exact duplicate journey rows, retaining one copy.
2. Exclude missing/invalid timestamps and non-positive durations.
3. Retain missing demographic data; represent as Unknown in Tableau.
4. Treat rider ages 13-105 as plausible. Invalid/missing ages become Unknown.
5. Retain Customer, Subscriber and rare Dependent user types.
6. Retain unmatched station IDs for system/temporal analysis. For station-level
   outputs, preserve the station ID but use Unknown / Historical Station and
   NULL geographic metadata when the reference table does not contain it.
*/

-- 3.1 Canonical cleaned trip-level dataset (inspection / validation query)
WITH params AS (
    SELECT 240.0::numeric AS max_valid_duration_minutes
),
all_trips AS (
    SELECT 2016 AS source_year, * FROM divvybikes_2016
    UNION ALL
    SELECT 2017 AS source_year, * FROM divvybikes_2017
    UNION ALL
    SELECT 2018 AS source_year, * FROM divvybikes_2018
    UNION ALL
    SELECT 2019 AS source_year, * FROM divvybikes_2019
),
exact_deduplicated AS (
    SELECT
        source_year,
        trip_id,
        bikeid,
        start_time,
        end_time,
        start_station_id,
        end_station_id,
        user_type,
        gender,
        birthyear
    FROM (
        SELECT
            a.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    trip_id,
                    bikeid,
                    start_time,
                    end_time,
                    start_station_id,
                    end_station_id,
                    user_type,
                    gender,
                    birthyear
                ORDER BY source_year
            ) AS exact_duplicate_row
        FROM all_trips a
    ) d
    WHERE exact_duplicate_row = 1
),
with_duration AS (
    SELECT
        d.*,
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 AS duration_minutes
    FROM exact_deduplicated d
    WHERE start_time IS NOT NULL
      AND end_time IS NOT NULL
      AND end_time > start_time
),
cleaned_trips AS (
    SELECT
        w.*,
        CASE
            WHEN birthyear IS NOT NULL
            THEN EXTRACT(YEAR FROM start_time)::int - birthyear
            ELSE NULL
        END AS rider_age
    FROM with_duration w
    CROSS JOIN params p
    WHERE duration_minutes > 0
      AND duration_minutes <= p.max_valid_duration_minutes
)
SELECT *
FROM cleaned_trips
ORDER BY start_time
LIMIT 100;


-- 3.2 Validation: cleaned trip counts by year
-- Expected counts for the current Tableau extract (4-hour threshold):
-- 2016 = 3,589,496
-- 2017 = 3,824,740
-- 2018 = 3,595,754
-- 2019 = 3,809,071
-- Total = 14,819,061
WITH params AS (
    SELECT 240.0::numeric AS max_valid_duration_minutes
),
all_trips AS (
    SELECT 2016 AS source_year, * FROM divvybikes_2016
    UNION ALL
    SELECT 2017 AS source_year, * FROM divvybikes_2017
    UNION ALL
    SELECT 2018 AS source_year, * FROM divvybikes_2018
    UNION ALL
    SELECT 2019 AS source_year, * FROM divvybikes_2019
),
exact_deduplicated AS (
    SELECT *
    FROM (
        SELECT
            a.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    trip_id,
                    bikeid,
                    start_time,
                    end_time,
                    start_station_id,
                    end_station_id,
                    user_type,
                    gender,
                    birthyear
                ORDER BY source_year
            ) AS exact_duplicate_row
        FROM all_trips a
    ) d
    WHERE exact_duplicate_row = 1
),
cleaned_trips AS (
    SELECT
        d.*,
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 AS duration_minutes
    FROM exact_deduplicated d
    CROSS JOIN params p
    WHERE start_time IS NOT NULL
      AND end_time IS NOT NULL
      AND end_time > start_time
      AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 > 0
      AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 <= p.max_valid_duration_minutes
)
SELECT
    source_year,
    COUNT(*) AS cleaned_trip_count
FROM cleaned_trips
GROUP BY source_year
ORDER BY source_year;


-- ====================================================================
