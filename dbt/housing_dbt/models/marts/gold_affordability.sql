{{ config(
    materialized='table',
    post_hook="COMMIT; DROP TABLE IF EXISTS pg.public.gold_affordability; CREATE TABLE pg.public.gold_affordability AS SELECT * FROM {{ this }}; BEGIN TRANSACTION;"
) }}

WITH listings_by_state AS (
    SELECT
        state,
        ROUND(AVG(price), 2) AS avg_price
    FROM {{ ref('stg_listings') }}
    WHERE state IS NOT NULL
    GROUP BY state
),
latest_mortgage AS (
    SELECT indicator_value AS mortgage_rate
    FROM (
        SELECT indicator_value,
               ROW_NUMBER() OVER(ORDER BY observation_date DESC) AS rn
        FROM {{ ref('stg_economic_indicators') }}
        WHERE series_id = 'MORTGAGE30US'
    )
    WHERE rn = 1
),
with_payment AS (
    SELECT
        l.state,
        l.avg_price,
        m.mortgage_rate AS current_mortgage_rate,
        -- Monthly payment: P&I on 80% LTV, 30-year fixed
        -- Formula: loan * (r(1+r)^n) / ((1+r)^n - 1) where r = monthly rate, n = 360
        ROUND(
            (l.avg_price * 0.80) *
            ((m.mortgage_rate / 100.0 / 12) * POWER(1 + (m.mortgage_rate / 100.0 / 12), 360))
            /
            (POWER(1 + (m.mortgage_rate / 100.0 / 12), 360) - 1)
        , 2) AS est_monthly_payment
    FROM listings_by_state l
    CROSS JOIN latest_mortgage m
)

SELECT
    state,
    avg_price,
    current_mortgage_rate,
    est_monthly_payment,
    CASE
        WHEN est_monthly_payment < 1000 THEN '$'
        WHEN est_monthly_payment < 2000 THEN '$$'
        WHEN est_monthly_payment < 3500 THEN '$$$'
        ELSE '$$$$'
    END AS affordability_tier
FROM with_payment
ORDER BY est_monthly_payment
