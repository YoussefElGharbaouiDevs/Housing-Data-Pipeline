{{ config(materialized='view') }}

WITH raw_data AS (
    SELECT *
    FROM read_parquet('s3://bronze/api/*.parquet')
)

SELECT
    TRY_CAST(date AS DATE) AS observation_date,
    TRY_CAST(value AS DOUBLE) AS indicator_value,
    TRY_CAST(series_id AS VARCHAR) AS series_id
FROM raw_data
WHERE date IS NOT NULL
  AND value IS NOT NULL
  AND value != '.'
