/*
 Divvy Bikeshare Analysis (2016–2019)
 PostgreSQL | Portfolio version
 Extracted from the complete project script for easier GitHub navigation.
*/

-- SECTION 4: TABLEAU TEMPORAL / DEMOGRAPHIC EXPORT
-- ====================================================================
/*
Output grain:
    trip_date x hour x user_type x gender x age_group

This compact aggregation supports:
    - executive KPIs
    - monthly trends
    - hour/day/season demand analysis
    - Customer vs Subscriber profiles
    - age/gender segmentation

Weighted average duration in Tableau must be calculated as:
    SUM(total_duration_minutes) / SUM(trip_count)
Do not average total_duration_minutes directly.
*/

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
cleaned AS (
    SELECT
        d.*,
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 AS duration_minutes,
        CASE
            WHEN birthyear IS NOT NULL
            THEN EXTRACT(YEAR FROM start_time)::int - birthyear
            ELSE NULL
        END AS rider_age
    FROM exact_deduplicated d
    CROSS JOIN params p
    WHERE start_time IS NOT NULL
      AND end_time IS NOT NULL
      AND end_time > start_time
      AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 > 0
      AND EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 <= p.max_valid_duration_minutes
),
features AS (
    SELECT
        start_time::date AS trip_date,
        EXTRACT(YEAR FROM start_time)::int AS trip_year,
        EXTRACT(QUARTER FROM start_time)::int AS quarter,
        EXTRACT(MONTH FROM start_time)::int AS month_number,
        TRIM(TO_CHAR(start_time, 'Month')) AS month_name,
        CASE
            WHEN EXTRACT(MONTH FROM start_time) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM start_time) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM start_time) IN (6, 7, 8) THEN 'Summer'
            ELSE 'Autumn'
        END AS season,
        EXTRACT(ISODOW FROM start_time)::int AS day_of_week_number,
        TRIM(TO_CHAR(start_time, 'Day')) AS day_of_week,
        CASE
            WHEN EXTRACT(ISODOW FROM start_time) IN (6, 7) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        EXTRACT(HOUR FROM start_time)::int AS start_hour,
        CASE
            WHEN EXTRACT(HOUR FROM start_time) BETWEEN 0 AND 5 THEN 'Night'
            WHEN EXTRACT(HOUR FROM start_time) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM start_time) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS time_of_day,
        COALESCE(NULLIF(TRIM(user_type), ''), 'Unknown') AS user_type,
        COALESCE(NULLIF(TRIM(gender), ''), 'Unknown') AS gender,
        CASE
            WHEN rider_age BETWEEN 13 AND 17 THEN '13-17'
            WHEN rider_age BETWEEN 18 AND 24 THEN '18-24'
            WHEN rider_age BETWEEN 25 AND 34 THEN '25-34'
            WHEN rider_age BETWEEN 35 AND 44 THEN '35-44'
            WHEN rider_age BETWEEN 45 AND 54 THEN '45-54'
            WHEN rider_age BETWEEN 55 AND 64 THEN '55-64'
            WHEN rider_age BETWEEN 65 AND 74 THEN '65-74'
            WHEN rider_age BETWEEN 75 AND 105 THEN '75+'
            ELSE 'Unknown'
        END AS age_group,
        duration_minutes
    FROM cleaned
)
SELECT
    trip_date,
    trip_year,
    quarter,
    month_number,
    month_name,
    season,
    day_of_week_number,
    day_of_week,
    day_type,
    start_hour,
    time_of_day,
    user_type,
    gender,
    age_group,
    COUNT(*) AS trip_count,
    ROUND(SUM(duration_minutes)::numeric, 2) AS total_duration_minutes
FROM features
GROUP BY
    trip_date,
    trip_year,
    quarter,
    month_number,
    month_name,
    season,
    day_of_week_number,
    day_of_week,
    day_type,
    start_hour,
    time_of_day,
    user_type,
    gender,
    age_group
ORDER BY
    trip_date,
    start_hour,
    user_type,
    gender,
    age_group;

-- Export the result of the query above from pgAdmin as:
-- bike_temporal_tableau.csv


-- ====================================================================
