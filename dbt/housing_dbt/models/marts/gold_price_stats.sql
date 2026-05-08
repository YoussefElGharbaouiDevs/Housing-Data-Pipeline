{{ config(
    materialized='table',
    post_hook="COMMIT; DROP TABLE IF EXISTS pg.public.gold_price_stats; CREATE TABLE pg.public.gold_price_stats AS SELECT * FROM {{ this }}; BEGIN TRANSACTION;"
) }}

WITH source AS (
    SELECT * FROM {{ ref('stg_listings') }}
),
latest_indicators AS (
    SELECT series_id, indicator_value
    FROM (
        SELECT series_id, indicator_value,
               ROW_NUMBER() OVER(PARTITION BY series_id ORDER BY observation_date DESC) as rn
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
    s.state,
    COUNT(*) AS total_listings,
    ROUND(AVG(s.price), 2) AS avg_price,
    COALESCE(ROUND(AVG(s.price / NULLIF(s.sqft, 0)), 2), 0) AS avg_price_per_sqft,
    MAX(s.price) AS max_price,
    MIN(s.price) AS min_price,
    MAX(i.current_mortgage_rate) AS current_mortgage_rate,
    MAX(i.current_case_shiller_index) AS current_case_shiller_index
FROM source s
CROSS JOIN pivoted_indicators i
WHERE s.state IS NOT NULL
GROUP BY s.state
