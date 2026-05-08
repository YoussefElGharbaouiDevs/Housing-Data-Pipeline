{{ config(
    materialized='table',
    post_hook="COMMIT; DROP TABLE IF EXISTS pg.public.gold_property_segments; CREATE TABLE pg.public.gold_property_segments AS SELECT * FROM {{ this }}; BEGIN TRANSACTION;"
) }}

WITH source AS (
    SELECT *,
        CASE
            WHEN bedrooms IS NULL THEN 'Unknown'
            WHEN bedrooms = 0 THEN 'Studio'
            WHEN bedrooms = 1 THEN '1-Bed'
            WHEN bedrooms = 2 THEN '2-Bed'
            WHEN bedrooms = 3 THEN '3-Bed'
            WHEN bedrooms = 4 THEN '4-Bed'
            ELSE '5+ Bed'
        END AS bedroom_segment,
        CASE
            WHEN bedrooms IS NULL THEN 6
            WHEN bedrooms = 0 THEN 0
            WHEN bedrooms = 1 THEN 1
            WHEN bedrooms = 2 THEN 2
            WHEN bedrooms = 3 THEN 3
            WHEN bedrooms = 4 THEN 4
            ELSE 5
        END AS segment_sort_order
    FROM {{ ref('stg_listings') }}
)

SELECT
    bedroom_segment,
    segment_sort_order,
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price,
    COALESCE(ROUND(AVG(price / NULLIF(sqft, 0)), 2), 0) AS avg_price_per_sqft,
    ROUND(AVG(sqft), 0) AS avg_sqft,
    ROUND(AVG(acre_lot), 3) AS avg_acre_lot
FROM source
GROUP BY bedroom_segment, segment_sort_order
ORDER BY segment_sort_order
