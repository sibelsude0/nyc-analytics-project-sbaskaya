-- Clean and standardize NYC Open Restaurant Applications data
-- One row per restaurant application

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        * EXCEPT (
            objectid,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            borough,
            zip,
            latitude,
            longitude,
            approved_for_sidewalk_seating,
            approved_for_roadway_seating,
            qualify_alcohol,
            time_of_submission
        ),

        -- Identifiers
        CAST(objectid AS STRING) AS restaurant_id,

        -- Name fields
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,

        -- Location - standardized borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        -- Location - clean zip code
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10
                AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
            THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip,

        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,

        -- Seating approvals as booleans
        UPPER(TRIM(CAST(approved_for_sidewalk_seating AS STRING))) = 'YES' AS approved_for_sidewalk_seating,
        UPPER(TRIM(CAST(approved_for_roadway_seating AS STRING))) = 'YES' AS approved_for_roadway_seating,
        UPPER(TRIM(CAST(qualify_alcohol AS STRING))) = 'YES' AS qualify_alcohol,

        -- Date/Time
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    WHERE objectid IS NOT NULL
)

SELECT * FROM cleaned