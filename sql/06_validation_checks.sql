/*
 Divvy Bikeshare Analysis (2016–2019)
 PostgreSQL | Portfolio version
 Extracted from the complete project script for easier GitHub navigation.
*/

-- SECTION 6: FINAL VALIDATION CHECKS
-- ====================================================================

-- 6.1 Confirm no invalid timestamps remain in the final trip logic
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
final_clean AS (
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
    COUNT(*) FILTER (WHERE end_time <= start_time) AS invalid_timestamps_remaining,
    COUNT(*) FILTER (WHERE duration_minutes <= 0) AS non_positive_durations_remaining,
    COUNT(*) FILTER (WHERE duration_minutes > 240) AS durations_over_4h_remaining
FROM final_clean;

-- Expected result: 0, 0, 0.


-- 6.2 Confirm the final temporal extract is internally consistent
-- Run against the exported CSV/Tableau source after loading if required:
-- SUM(trip_count) should equal 14,819,061 for the current 4-hour extract.

-- ====================================================================
-- END OF SQL PREPARATION SCRIPT
-- ====================================================================
