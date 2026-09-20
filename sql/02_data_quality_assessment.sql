/*
 Divvy Bikeshare Analysis (2016–2019)
 PostgreSQL | Portfolio version
 Extracted from the complete project script for easier GitHub navigation.
*/

-- SECTION 2: DATA QUALITY ASSESSMENT
-- ====================================================================

--2.1 Missing Values for each table

SELECT
    2016 AS year,
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE trip_id IS NULL) AS trip_id_nulls,
    COUNT(*) FILTER (WHERE bikeid IS NULL) AS bikeid_nulls,
    COUNT(*) FILTER (WHERE start_time IS NULL) AS start_time_nulls,
    COUNT(*) FILTER (WHERE end_time IS NULL) AS end_time_nulls,
    COUNT(*) FILTER (WHERE start_station_id IS NULL) AS start_station_nulls,
    COUNT(*) FILTER (WHERE end_station_id IS NULL) AS end_station_nulls,
    COUNT(*) FILTER (WHERE user_type IS NULL) AS user_type_nulls,
    COUNT(*) FILTER (WHERE gender IS NULL) AS gender_nulls,
    COUNT(*) FILTER (WHERE birthyear IS NULL) AS birthyear_nulls

FROM divvybikes_2016 

UNION ALL 

SELECT
    2017,
    COUNT(*),
    COUNT(*) FILTER (WHERE trip_id IS NULL),
    COUNT(*) FILTER (WHERE bikeid IS NULL),
    COUNT(*) FILTER (WHERE start_time IS NULL),
    COUNT(*) FILTER (WHERE end_time IS NULL),
    COUNT(*) FILTER (WHERE start_station_id IS NULL),
    COUNT(*) FILTER (WHERE end_station_id IS NULL),
    COUNT(*) FILTER (WHERE user_type IS NULL),
    COUNT(*) FILTER (WHERE gender IS NULL),
    COUNT(*) FILTER (WHERE birthyear IS NULL)
FROM divvybikes_2017

UNION ALL

SELECT
    2018,
    COUNT(*),
    COUNT(*) FILTER (WHERE trip_id IS NULL),
    COUNT(*) FILTER (WHERE bikeid IS NULL),
    COUNT(*) FILTER (WHERE start_time IS NULL),
    COUNT(*) FILTER (WHERE end_time IS NULL),
    COUNT(*) FILTER (WHERE start_station_id IS NULL),
    COUNT(*) FILTER (WHERE end_station_id IS NULL),
    COUNT(*) FILTER (WHERE user_type IS NULL),
    COUNT(*) FILTER (WHERE gender IS NULL),
    COUNT(*) FILTER (WHERE birthyear IS NULL)
FROM divvybikes_2018

UNION ALL

SELECT
    2019,
    COUNT(*),
    COUNT(*) FILTER (WHERE trip_id IS NULL),
    COUNT(*) FILTER (WHERE bikeid IS NULL),
    COUNT(*) FILTER (WHERE start_time IS NULL),
    COUNT(*) FILTER (WHERE end_time IS NULL),
    COUNT(*) FILTER (WHERE start_station_id IS NULL),
    COUNT(*) FILTER (WHERE end_station_id IS NULL),
    COUNT(*) FILTER (WHERE user_type IS NULL),
    COUNT(*) FILTER (WHERE gender IS NULL),
    COUNT(*) FILTER (WHERE birthyear IS NULL)
FROM divvybikes_2019

ORDER BY year;

--2.2 Duplicate trip IDs 
-- Script identifies identical trip IDs in our data (61 duplicates)
WITH all_trips AS (

    SELECT 2016 AS source_year, *
    FROM divvybikes_2016
    UNION ALL

    SELECT 2017 AS source_year, *
    FROM divvybikes_2017
    UNION ALL

    SELECT 2018 AS source_year, *
    FROM divvybikes_2018
    UNION ALL

    SELECT 2019 AS source_year, *
    FROM divvybikes_2019
),
duplicate_ids AS (
    SELECT trip_id
    FROM all_trips
    GROUP BY trip_id
    HAVING COUNT(*) > 1

)

SELECT a.*
FROM all_trips a
INNER JOIN duplicate_ids d
    ON a.trip_id = d.trip_id
ORDER BY a.trip_id, a.source_year, a.start_time; 

-- 2.3 Invalid timestamps 
-- Script identifies records with an invalid end_time (31 records)
SELECT * 
FROM ( 
	SELECT 2016 AS source_year, 
	* FROM divvybikes_2016
	UNION ALL 
	
	SELECT 2017 AS source_year, 
	* FROM divvybikes_2017 
	UNION ALL 
	
	SELECT 2018 AS source_year, 
	* FROM divvybikes_2018 
	UNION ALL 
	
	SELECT 2019 AS source_year, 
	* FROM divvybikes_2019 
	) AS trips 
WHERE end_time <= start_time 
ORDER BY source_year, start_time; 

-- 2.4 Trip duration anomalies? 

WITH all_trips AS (
    SELECT 2016 AS source_year, start_time, end_time
    FROM divvybikes_2016

    UNION ALL

    SELECT 2017, start_time, end_time
    FROM divvybikes_2017

    UNION ALL

    SELECT 2018, start_time, end_time
    FROM divvybikes_2018

    UNION ALL

    SELECT 2019, start_time, end_time
    FROM divvybikes_2019
),

durations AS (
    SELECT
        source_year,
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0
            AS duration_minutes
    FROM all_trips
    WHERE end_time > start_time
)

SELECT
    source_year,
    COUNT(*) AS total_valid_trips,
    ROUND(MIN(duration_minutes)::numeric, 2) AS min_duration,
    ROUND(AVG(duration_minutes)::numeric, 2) AS avg_duration,
    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY duration_minutes)::numeric,
        2
    ) AS median_duration,
    ROUND(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY duration_minutes)::numeric,
        2
    ) AS p95_duration,
    ROUND(
        PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY duration_minutes)::numeric,
        2
    ) AS p99_duration,
    ROUND(MAX(duration_minutes)::numeric, 2) AS max_duration
FROM durations
GROUP BY source_year
ORDER BY source_year;

-- inspecting the extreme journeys 

WITH all_trips AS ( 
	SELECT 2016 AS source_year, 
	* FROM divvybikes_2016 
	UNION ALL 
	SELECT 2017, 
	* FROM divvybikes_2017 
	UNION ALL 
	SELECT 2018, 
	* FROM divvybikes_2018 
	UNION ALL 
	SELECT 2019, * FROM divvybikes_2019
) 
SELECT 
	source_year, 
	trip_id, 
	bikeid, 
	start_time, 
	end_time, 
	ROUND( 
		(EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0)::numeric, 2)
		AS duration_minutes, 
	start_station_id, 
	end_station_id, 
	user_type 
FROM all_trips 
WHERE end_time > start_time 
ORDER BY duration_minutes DESC 
LIMIT 200; 

-- 

WITH all_trips AS (
    SELECT 2016 AS source_year, start_time, end_time
    FROM divvybikes_2016

    UNION ALL

    SELECT 2017, start_time, end_time
    FROM divvybikes_2017

    UNION ALL

    SELECT 2018, start_time, end_time
    FROM divvybikes_2018

    UNION ALL

    SELECT 2019, start_time, end_time
    FROM divvybikes_2019
),

durations AS (
    SELECT
        source_year,
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0
            AS duration_minutes
    FROM all_trips
    WHERE end_time > start_time
)

SELECT
    source_year,
    COUNT(*) AS total_trips,

    COUNT(*) FILTER (
        WHERE duration_minutes <= 60
    ) AS under_1_hour,

    COUNT(*) FILTER (
        WHERE duration_minutes > 60
        AND duration_minutes <= 120
    ) AS between_1_and_2_hours,

    COUNT(*) FILTER (
        WHERE duration_minutes > 120
        AND duration_minutes <= 1440
    ) AS between_2_and_24_hours,

	COUNT(*) FILTER ( 
		WHERE duration_minutes > 180 
		AND duration_minutes <= 1440
	) AS between_3_and_24_hours,

	COUNT(*) FILTER (
		WHERE duration_minutes > 240 
		AND duration_minutes <= 1440
	) AS between_4_and_24_hours,

    COUNT(*) FILTER (
        WHERE duration_minutes > 1440
    ) AS over_24_hours

FROM durations
GROUP BY source_year
ORDER BY source_year;

-- 2.4.1 extreme duration by month


WITH all_trips AS (
    SELECT 2016 AS source_year, start_time, end_time
    FROM divvybikes_2016

    UNION ALL

    SELECT 2017, start_time, end_time
    FROM divvybikes_2017

    UNION ALL

    SELECT 2018, start_time, end_time
    FROM divvybikes_2018

    UNION ALL

    SELECT 2019, start_time, end_time
    FROM divvybikes_2019
),

durations AS (
    SELECT
        source_year,
        start_time,
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0
            AS duration_minutes
    FROM all_trips
    WHERE end_time > start_time
)

SELECT
    source_year,
    EXTRACT(MONTH FROM start_time) AS start_month,
    COUNT(*) AS trips_over_24_hours
FROM durations
WHERE duration_minutes > 1440
GROUP BY source_year, EXTRACT(MONTH FROM start_time)
ORDER BY source_year, start_month;

-- further investigation by user type to understand anomalous journeys

WITH all_trips AS (
    SELECT 2016 AS source_year, start_time, end_time, user_type
    FROM divvybikes_2016

    UNION ALL

    SELECT 2017, start_time, end_time, user_type
    FROM divvybikes_2017

    UNION ALL

    SELECT 2018, start_time, end_time, user_type
    FROM divvybikes_2018

    UNION ALL

    SELECT 2019, start_time, end_time, user_type
    FROM divvybikes_2019
) 
SELECT 
	source_year, 
	user_type, 
	COUNT(*) AS trips_over_24_hours
FROM all_trips 
WHERE EXTRACT(EPOCH FROM (end_time - start_time)) / 60.0 > 1440 
GROUP BY source_year, user_type 
ORDER BY source_year, trips_over_24_hours DESC;

-- investigating by end station 

WITH all_trips AS (
    SELECT 2016 AS source_year,
           start_time,
           end_time,
           end_station_id
    FROM divvybikes_2016

    UNION ALL

    SELECT 2017, start_time, end_time, end_station_id
    FROM divvybikes_2017

    UNION ALL

    SELECT 2018, start_time, end_time, end_station_id
    FROM divvybikes_2018

    UNION ALL

    SELECT 2019, start_time, end_time, end_station_id
    FROM divvybikes_2019
)

SELECT
    t.source_year,
    t.end_station_id,
    s.name AS station_name,
    COUNT(*) AS trips_over_24_hours
FROM all_trips t

LEFT JOIN divvy_stations s
    ON t.end_station_id = s.id

WHERE EXTRACT(EPOCH FROM (t.end_time - t.start_time)) / 60.0 > 1440

GROUP BY
    t.source_year,
    t.end_station_id,
    s.name

ORDER BY
    t.source_year,
    trips_over_24_hours DESC;

-- same thing for starting stations: 

WITH all_trips AS (
    SELECT 2016 AS source_year,
           start_time,
           end_time,
           start_station_id
    FROM divvybikes_2016

    UNION ALL

    SELECT 2017, start_time, end_time, start_station_id
    FROM divvybikes_2017

    UNION ALL

    SELECT 2018, start_time, end_time, start_station_id
    FROM divvybikes_2018

    UNION ALL

    SELECT 2019, start_time, end_time, start_station_id
    FROM divvybikes_2019
)

SELECT
    t.source_year,
    t.start_station_id,
    s.name AS station_name,
    COUNT(*) AS trips_over_24_hours
FROM all_trips t

LEFT JOIN divvy_stations s
    ON t.start_station_id = s.id

WHERE EXTRACT(EPOCH FROM (t.end_time - t.start_time)) / 60.0 > 1440

GROUP BY
    t.source_year,
    t.start_station_id,
    s.name

ORDER BY
    t.source_year,
    trips_over_24_hours DESC;

-- 2.5 Birth year validation 

WITH all_trips AS (
    SELECT 2016 AS source_year, birthyear FROM divvybikes_2016
    UNION ALL
    SELECT 2017, birthyear FROM divvybikes_2017
    UNION ALL
    SELECT 2018, birthyear FROM divvybikes_2018
    UNION ALL
    SELECT 2019, birthyear FROM divvybikes_2019
)

SELECT
    source_year,
    MIN(birthyear) AS earliest_birthyear,
    MAX(birthyear) AS latest_birthyear,
    COUNT(*) FILTER (WHERE birthyear IS NULL) AS null_birthyears
FROM all_trips
GROUP BY source_year
ORDER BY source_year;

------- 

WITH all_trips AS (
    SELECT 2016 AS source_year, birthyear FROM divvybikes_2016
    UNION ALL
    SELECT 2017, birthyear FROM divvybikes_2017
    UNION ALL
    SELECT 2018, birthyear FROM divvybikes_2018
    UNION ALL
    SELECT 2019, birthyear FROM divvybikes_2019
)

SELECT
    birthyear,
    COUNT(*) AS trips
FROM all_trips
WHERE birthyear IS NOT NULL
GROUP BY birthyear
ORDER BY birthyear;

---- 
-- =========================================================
-- 2.6.2 AGE VALIDATION
-- =========================================================
-- Purpose:
-- Calculate approximate rider age at the time of each trip
-- and identify implausible demographic records.

WITH all_trips AS (

    SELECT 2016 AS source_year, trip_id, start_time, birthyear
    FROM divvybikes_2016

    UNION ALL

    SELECT 2017, trip_id, start_time, birthyear
    FROM divvybikes_2017

    UNION ALL

    SELECT 2018, trip_id, start_time, birthyear
    FROM divvybikes_2018

    UNION ALL

    SELECT 2019, trip_id, start_time, birthyear
    FROM divvybikes_2019
),

ages AS (

    SELECT
        *,
        EXTRACT(YEAR FROM start_time)::int - birthyear AS rider_age
    FROM all_trips
    WHERE birthyear IS NOT NULL
)

SELECT
    rider_age,
    COUNT(*) AS trip_count
FROM ages
GROUP BY rider_age
ORDER BY rider_age;

-- 2.6 Checking categorical attributes 

WITH all_trips AS (
    SELECT
        2016 AS source_year,
        user_type,
        gender,
        birthyear
    FROM divvybikes_2016
    UNION ALL

    SELECT
        2017,
        user_type,
        gender,
        birthyear
    FROM divvybikes_2017
    UNION ALL

    SELECT
        2018,
        user_type,
        gender,
        birthyear
    FROM divvybikes_2018
    UNION ALL

    SELECT
        2019,
        user_type,
        gender,
        birthyear
    FROM divvybikes_2019
)

SELECT
    source_year,
    user_type,
    gender,
    COUNT(*) AS trip_count,
    COUNT(*) FILTER (WHERE gender IS NULL
   	) AS gender_nulls,

    COUNT(*) FILTER (WHERE birthyear IS NULL
    ) AS birthyear_nulls,

    COUNT(*) FILTER (WHERE gender IS NULL
          AND birthyear IS NULL
    ) AS both_demographics_null,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE gender IS NULL)
        / COUNT(*),
        2
    ) AS pct_gender_null,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE birthyear IS NULL)
        / COUNT(*),
        2
    ) AS pct_birthyear_null
FROM all_trips
GROUP BY
    source_year,
    user_type,
    gender
ORDER BY
    source_year,
    user_type,
    gender;

-- 2.7 Station referential integrity 

WITH all_trips AS ( 
	SELECT 2016 AS source_year, 
	start_station_id, 
	end_station_id 
	FROM divvybikes_2016 
	UNION ALL 
	
	SELECT 2017, 
	start_station_id, 
	end_station_id 
	FROM divvybikes_2017 
	UNION ALL 
	
	SELECT 2018, 
	start_station_id, 
	end_station_id 
	FROM divvybikes_2018 
	UNION ALL 

	SELECT 2019, 
	start_station_id, 
	end_station_id 
	FROM divvybikes_2019
	) 

SELECT 
	t.source_year, 
	COUNT(*) AS total_trips, 
	COUNT(*) FILTER (
        WHERE t.start_station_id IS NULL
    ) AS null_start_station,

    COUNT(*) FILTER (
        WHERE t.end_station_id IS NULL
    ) AS null_end_station,

    COUNT(*) FILTER (
        WHERE t.start_station_id IS NOT NULL
          AND ss.id IS NULL
    ) AS unmatched_start_station,

    COUNT(*) FILTER (
        WHERE t.end_station_id IS NOT NULL
          AND es.id IS NULL
    ) AS unmatched_end_station,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t.start_station_id IS NOT NULL
              AND ss.id IS NULL
        ) / COUNT(*),
        3
    ) AS pct_unmatched_start,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t.end_station_id IS NOT NULL
              AND es.id IS NULL
        ) / COUNT(*),
        3
    ) AS pct_unmatched_end

FROM all_trips t

LEFT JOIN divvy_stations ss
    ON t.start_station_id = ss.id

LEFT JOIN divvy_stations es
    ON t.end_station_id = es.id

GROUP BY t.source_year
ORDER BY t.source_year;


-- =========================================================
-- 2.8.2 INVESTIGATE UNMATCHED STATION IDs
-- =========================================================

WITH all_trips AS (

    SELECT
        2016 AS source_year,
        start_station_id,
        end_station_id
    FROM divvybikes_2016

    UNION ALL

    SELECT 2017, start_station_id, end_station_id
    FROM divvybikes_2017

    UNION ALL

    SELECT 2018, start_station_id, end_station_id
    FROM divvybikes_2018

    UNION ALL

    SELECT 2019, start_station_id, end_station_id
    FROM divvybikes_2019
),

station_ids AS (

    SELECT
        source_year,
        'Start' AS station_type,
        start_station_id AS station_id
    FROM all_trips

    UNION ALL

    SELECT
        source_year,
        'End',
        end_station_id
    FROM all_trips
)

SELECT
    s.source_year,
    s.station_type,
    s.station_id,
    COUNT(*) AS affected_trips

FROM station_ids s

LEFT JOIN divvy_stations d
    ON s.station_id = d.id

WHERE s.station_id IS NOT NULL
  AND d.id IS NULL

GROUP BY
    s.source_year,
    s.station_type,
    s.station_id

ORDER BY
    s.source_year,
    affected_trips DESC; 

---


-- Check station reference table quality

SELECT
    COUNT(*) AS total_stations,

    COUNT(*) FILTER (WHERE id IS NULL) AS null_ids,

    COUNT(*) FILTER (WHERE name IS NULL) AS null_names,

    COUNT(*) FILTER (WHERE latitude IS NULL) AS null_latitudes,

    COUNT(*) FILTER (WHERE longitude IS NULL) AS null_longitudes,

    COUNT(*) FILTER (WHERE docks IS NULL) AS null_docks,

    COUNT(DISTINCT id) AS unique_station_ids

FROM divvy_stations;

-- ====================================================================
