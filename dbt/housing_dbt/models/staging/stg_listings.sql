{{ config(materialized='view') }}

WITH raw_data AS (
    SELECT *
    FROM read_parquet('s3://bronze/dataset/*.parquet')
)

SELECT
    TRY_CAST(city AS VARCHAR) AS city,
    TRY_CAST(state AS VARCHAR) AS state,
    TRY_CAST(zip_code AS VARCHAR) AS zip_code,
    TRY_CAST(price AS DOUBLE) AS price,
    TRY_CAST(bed AS INT) AS bedrooms,
    TRY_CAST(bath AS DOUBLE) AS bathrooms,
    TRY_CAST(house_size AS DOUBLE) AS sqft,
    TRY_CAST(acre_lot AS DOUBLE) AS acre_lot
FROM raw_data
WHERE price IS NOT NULL
