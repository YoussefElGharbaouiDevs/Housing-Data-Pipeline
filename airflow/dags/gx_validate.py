import sys
import great_expectations as gx
import great_expectations.expectations as gxe

def run_validation():
    print("Initializing Great Expectations Context...")
    # Use ephemeral context so we don't need a heavy local gx folder structure
    context = gx.get_context(mode="ephemeral")

    print("Connecting to PostgreSQL Data Warehouse...")
    # This connection string matches the one used by Airflow and Metabase in docker-compose
    connection_string = "postgresql+psycopg2://airflow:airflow@postgres:5432/datawarehouse"
    
    try:
        datasource = context.data_sources.add_postgres(
            name="postgres_dw",
            connection_string=connection_string
        )
    except Exception as e:
        print(f"Datasource already exists or error: {e}")
        datasource = context.data_sources.get("postgres_dw")

    # Add the table we want to validate (Gold Layer)
    table_name = "gold_market_overview"
    print(f"Adding table asset for {table_name}...")
    try:
        asset = datasource.add_table_asset(name=table_name, table_name=table_name)
    except Exception as e:
        asset = datasource.get_asset(table_name)

    print("Creating Expectation Suite...")
    suite_name = "gold_market_overview_suite"
    try:
        suite = context.suites.get(name=suite_name)
    except Exception:
        suite = gx.ExpectationSuite(name=suite_name)
        suite = context.suites.add(suite)
    
    print("Defining Expectations...")
    suite.add_expectation(gxe.ExpectTableRowCountToBeBetween(min_value=1))
    suite.add_expectation(gxe.ExpectColumnValuesToNotBeNull(column="total_listings"))
    suite.add_expectation(gxe.ExpectColumnValuesToBeBetween(column="national_avg_price", min_value=1))
    suite.add_expectation(gxe.ExpectTableColumnsToMatchSet(column_set=[
        "total_listings",
        "total_states",
        "total_cities",
        "national_avg_price",
        "national_median_price",
        "national_avg_price_per_sqft",
        "current_mortgage_rate",
        "current_case_shiller_index"
    ]))

    try:
        batch_definition = asset.get_batch_definition("batch_def")
    except Exception:
        batch_definition = asset.add_batch_definition_whole_table("batch_def")
        
    validation_definition = gx.ValidationDefinition(
        name="my_validation_def",
        data=batch_definition,
        suite=suite,
    )
    
    try:
        validation_definition = context.validation_definitions.get("my_validation_def")
    except Exception:
        validation_definition = context.validation_definitions.add(validation_definition)

    print("Running Checkpoint Validation...")
    checkpoint = gx.Checkpoint(
        name="daily_market_overview_checkpoint",
        validation_definitions=[validation_definition]
    )
    
    try:
        checkpoint = context.checkpoints.get("daily_market_overview_checkpoint")
    except Exception:
        checkpoint = context.checkpoints.add(checkpoint)

    result = checkpoint.run()

    if not result.success:
        print("Data Quality Validation FAILED! Check Great Expectations logs.")
        sys.exit(1)
    else:
        print("Data Quality Validation PASSED! Data is safe for consumption.")
        sys.exit(0)

if __name__ == "__main__":
    run_validation()
