$token = "c7ec2cad-a357-4a99-98d3-54f98f9a0dcc"
$headers = @{
    "Content-Type"    = "application/json"
    "X-Metabase-Session" = $token
}
$dbId = 2

# ── Helper: Create a saved question (card) ──
function New-Card {
    param($Name, $Display, $Query, $Viz)
    $body = @{
        name                  = $Name
        display               = $Display
        dataset_query         = @{
            type     = "native"
            native   = @{ query = $Query }
            database = $dbId
        }
        visualization_settings = if ($Viz) { $Viz } else { @{} }
    } | ConvertTo-Json -Depth 10
    $card = Invoke-RestMethod -Uri "http://localhost:3000/api/card" -Method POST -Headers $headers -Body $body
    Write-Host "  Created card '$Name' (id=$($card.id))"
    return $card.id
}

Write-Host "`n=== Creating Saved Questions ===`n"

# ── 1. KPI Cards (from gold_market_overview) ──
$c1 = New-Card -Name "Total Listings" -Display "scalar" -Query "SELECT total_listings FROM gold_market_overview" -Viz @{
    "scalar.field" = "total_listings"
}

$c2 = New-Card -Name "National Avg Price" -Display "scalar" -Query "SELECT national_avg_price FROM gold_market_overview" -Viz @{
    "scalar.field"  = "national_avg_price"
    "number_style"  = "currency"
    "currency"      = "USD"
}

$c3 = New-Card -Name "National Median Price" -Display "scalar" -Query "SELECT national_median_price FROM gold_market_overview" -Viz @{
    "scalar.field"  = "national_median_price"
    "number_style"  = "currency"
    "currency"      = "USD"
}

$c4 = New-Card -Name "Current Mortgage Rate (%)" -Display "scalar" -Query "SELECT current_mortgage_rate FROM gold_market_overview" -Viz @{
    "scalar.field" = "current_mortgage_rate"
    "number_suffix" = "%"
}

$c5 = New-Card -Name "Case-Shiller Index" -Display "scalar" -Query "SELECT current_case_shiller_index FROM gold_market_overview" -Viz @{
    "scalar.field" = "current_case_shiller_index"
}

$c6 = New-Card -Name "Avg Price per Sqft" -Display "scalar" -Query "SELECT national_avg_price_per_sqft FROM gold_market_overview" -Viz @{
    "scalar.field"  = "national_avg_price_per_sqft"
    "number_style"  = "currency"
    "currency"      = "USD"
}

# ── 2. Affordability by State (bar chart) ──
$c7 = New-Card -Name "Monthly Payment by State" -Display "bar" `
    -Query "SELECT state, est_monthly_payment, affordability_tier FROM gold_affordability ORDER BY est_monthly_payment" `
    -Viz @{
        "graph.x_axis.title_text" = "State"
        "graph.y_axis.title_text" = "Est. Monthly Payment ($)"
    }

# ── 3. Affordability Tier Distribution (pie) ──
$c8 = New-Card -Name "Affordability Tier Distribution" -Display "pie" `
    -Query "SELECT affordability_tier, COUNT(*) as count FROM gold_affordability GROUP BY affordability_tier ORDER BY affordability_tier"

# ── 4. Average Price by State (bar) ──
$c9 = New-Card -Name "Avg Price by State" -Display "bar" `
    -Query "SELECT state, avg_price FROM gold_price_stats ORDER BY avg_price DESC" `
    -Viz @{
        "graph.x_axis.title_text" = "State"
        "graph.y_axis.title_text" = "Average Price ($)"
    }

# ── 5. Price per Sqft by State (bar) ──
$c10 = New-Card -Name "Price per Sqft by State" -Display "bar" `
    -Query "SELECT state, avg_price_per_sqft FROM gold_price_stats ORDER BY avg_price_per_sqft DESC" `
    -Viz @{
        "graph.x_axis.title_text" = "State"
        "graph.y_axis.title_text" = "Avg Price per Sqft ($)"
    }

# ── 6. Listings by State (row chart) ──
$c11 = New-Card -Name "Listings by State" -Display "row" `
    -Query "SELECT state, total_listings FROM gold_price_stats ORDER BY total_listings DESC"

# ── 7. Property Segments - Avg Price (bar) ──
$c12 = New-Card -Name "Avg Price by Bedroom Segment" -Display "bar" `
    -Query "SELECT bedroom_segment, avg_price FROM gold_property_segments ORDER BY segment_sort_order" `
    -Viz @{
        "graph.x_axis.title_text" = "Bedroom Segment"
        "graph.y_axis.title_text" = "Average Price ($)"
    }

# ── 8. Property Segments - Listings Count (bar) ──
$c13 = New-Card -Name "Listings by Bedroom Segment" -Display "bar" `
    -Query "SELECT bedroom_segment, total_listings FROM gold_property_segments ORDER BY segment_sort_order" `
    -Viz @{
        "graph.x_axis.title_text" = "Bedroom Segment"
        "graph.y_axis.title_text" = "Total Listings"
    }

# ── 9. Top 20 Cities by Avg Price (table) ──
$c14 = New-Card -Name "Top 20 Most Expensive Cities" -Display "table" `
    -Query "SELECT city, state, avg_price, median_price, avg_price_per_sqft, total_listings FROM gold_city_stats ORDER BY avg_price DESC LIMIT 20"

# ── 10. Top 20 Cities by Listings (table) ──
$c15 = New-Card -Name "Top 20 Cities by Listings" -Display "table" `
    -Query "SELECT city, state, total_listings, avg_price, median_price, avg_bedrooms, avg_sqft FROM gold_city_stats ORDER BY total_listings DESC LIMIT 20"

# ── 11. Price Range by State (min/max) ──
$c16 = New-Card -Name "Price Range by State (Min vs Max)" -Display "bar" `
    -Query "SELECT state, min_price, max_price FROM gold_price_stats ORDER BY max_price DESC" `
    -Viz @{
        "graph.x_axis.title_text" = "State"
        "graph.y_axis.title_text" = "Price ($)"
        "stackable.stack_type"    = $null
    }

# ── 12. Avg Sqft by Segment (bar) ──
$c17 = New-Card -Name "Avg Sqft by Bedroom Segment" -Display "bar" `
    -Query "SELECT bedroom_segment, avg_sqft FROM gold_property_segments ORDER BY segment_sort_order" `
    -Viz @{
        "graph.x_axis.title_text" = "Bedroom Segment"
        "graph.y_axis.title_text" = "Avg Sqft"
    }

Write-Host "`n=== Creating Dashboard ===`n"

# ── Create the Dashboard ──
$dashBody = @{
    name        = "US Housing Market Dashboard"
    description = "Comprehensive overview of the US housing market including pricing, affordability, property segments, and city-level statistics."
} | ConvertTo-Json -Depth 5
$dash = Invoke-RestMethod -Uri "http://localhost:3000/api/dashboard" -Method POST -Headers $headers -Body $dashBody
$dashId = $dash.id
Write-Host "  Created dashboard (id=$dashId)"

# ── Add cards to dashboard with layout ──
# Layout: 24-column grid. Each card has col, row, size_x, size_y
$cards = @(
    # Row 0: KPI cards (6 across, 4 units each)
    @{ id = $c1;  col = 0;  row = 0;  size_x = 4;  size_y = 3 }
    @{ id = $c2;  col = 4;  row = 0;  size_x = 4;  size_y = 3 }
    @{ id = $c3;  col = 8;  row = 0;  size_x = 4;  size_y = 3 }
    @{ id = $c4;  col = 12; row = 0;  size_x = 4;  size_y = 3 }
    @{ id = $c5;  col = 16; row = 0;  size_x = 4;  size_y = 3 }
    @{ id = $c6;  col = 20; row = 0;  size_x = 4;  size_y = 3 }

    # Row 3: Affordability charts
    @{ id = $c7;  col = 0;  row = 3;  size_x = 12; size_y = 6 }
    @{ id = $c8;  col = 12; row = 3;  size_x = 12; size_y = 6 }

    # Row 9: State price analysis
    @{ id = $c9;  col = 0;  row = 9;  size_x = 12; size_y = 6 }
    @{ id = $c10; col = 12; row = 9;  size_x = 12; size_y = 6 }

    # Row 15: Listings + Price Range
    @{ id = $c11; col = 0;  row = 15; size_x = 8;  size_y = 6 }
    @{ id = $c16; col = 8;  row = 15; size_x = 16; size_y = 6 }

    # Row 21: Property segments
    @{ id = $c12; col = 0;  row = 21; size_x = 8;  size_y = 6 }
    @{ id = $c13; col = 8;  row = 21; size_x = 8;  size_y = 6 }
    @{ id = $c17; col = 16; row = 21; size_x = 8;  size_y = 6 }

    # Row 27: City tables
    @{ id = $c14; col = 0;  row = 27; size_x = 12; size_y = 8 }
    @{ id = $c15; col = 12; row = 27; size_x = 12; size_y = 8 }
)

Write-Host "`n=== Adding Cards to Dashboard ===`n"

foreach ($c in $cards) {
    $cardBody = @{
        cardId = $c.id
        col    = $c.col
        row    = $c.row
        size_x = $c.size_x
        size_y = $c.size_y
    } | ConvertTo-Json -Depth 5
    $result = Invoke-RestMethod -Uri "http://localhost:3000/api/dashboard/$dashId" -Method PUT -Headers $headers -Body (@{
        dashcards = @(@{
            id         = -1
            card_id    = $c.id
            col        = $c.col
            row        = $c.row
            size_x     = $c.size_x
            size_y     = $c.size_y
        })
    } | ConvertTo-Json -Depth 5)
    Write-Host "  Added card $($c.id) at ($($c.col), $($c.row))"
}

Write-Host "`n=== Done! ===`n"
Write-Host "Dashboard URL: http://localhost:3000/dashboard/$dashId"
