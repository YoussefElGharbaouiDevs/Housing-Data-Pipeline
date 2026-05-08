{{ config(
    materialized='table',
    post_hook="COMMIT; DROP TABLE IF EXISTS pg.public.gold_city_stats; CREATE TABLE pg.public.gold_city_stats AS SELECT * FROM {{ this }}; BEGIN TRANSACTION;"
) }}

WITH source AS (
    SELECT * FROM {{ ref('stg_listings') }}
)

SELECT
    state,
    city,
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price), 2) AS median_price,
    COALESCE(ROUND(AVG(price / NULLIF(sqft, 0)), 2), 0) AS avg_price_per_sqft,
    ROUND(AVG(bedrooms), 1) AS avg_bedrooms,
    ROUND(AVG(sqft), 0) AS avg_sqft
FROM source
WHERE state IS NOT NULL
  AND city IS NOT NULL
GROUP BY state, city
