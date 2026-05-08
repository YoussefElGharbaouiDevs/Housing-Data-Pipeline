{{ config(
    materialized='table',
    post_hook="COMMIT; DROP TABLE IF EXISTS pg.public.gold_market_overview; CREATE TABLE pg.public.gold_market_overview AS SELECT * FROM {{ this }}; BEGIN TRANSACTION;"
) }}

WITH listings AS (
    SELECT * FROM {{ ref('stg_listings') }}
),
listing_stats AS (
    SELECT
        COUNT(*) AS total_listings,
        COUNT(DISTINCT state) AS total_states,
        COUNT(DISTINCT city) AS total_cities,
        ROUND(AVG(price), 2) AS national_avg_price,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price), 2) AS national_median_price,
        COALESCE(ROUND(AVG(price / NULLIF(sqft, 0)), 2), 0) AS national_avg_price_per_sqft
    FROM listings
),
latest_indicators AS (
    SELECT series_id, indicator_value
    FROM (
        SELECT series_id, indicator_value,
               ROW_NUMBER() OVER(PARTITION BY series_id ORDER BY observation_date DESC) AS rn
        FROM {{ ref('stg_economic_indicators') }}
    )
    WHERE rn = 1
),
pivoted_indicators AS (
    SELECT
        MAX(CASE WHEN series_id = 'MORTGAGE30US' THEN indicator_value END) AS current_mortgage_rate,
        MAX(CASE WHEN series_id = 'CSUSHPINSA' THEN indicator_value END) AS current_case_shiller_index
    FROM latest_indicators
)

SELECT
    ls.total_listings,
    ls.total_states,
    ls.total_cities,
    ls.national_avg_price,
    ls.national_median_price,
    ls.national_avg_price_per_sqft,
    pi.current_mortgage_rate,
    pi.current_case_shiller_index
FROM listing_stats ls
CROSS JOIN pivoted_indicators pi
