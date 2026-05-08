from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'data_engineer',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'housing_data_pipeline',
    default_args=default_args,
    description='End-to-End Housing Data Pipeline',
    schedule_interval=timedelta(days=1),
    catchup=False,
    tags=['housing', 'dbt', 'kafka'],
) as dag:

    # 1. Ingestion: Producer
    # Runs the producer script to read CSV and send to Kafka
    run_producer = BashOperator(
        task_id='run_kafka_producer',
        bash_command='python /opt/airflow/ingestion/producer.py'
    )

    # 2. Ingestion: Consumer
    # Runs the consumer script to read from Kafka and write to MinIO
    run_consumer = BashOperator(
        task_id='run_kafka_consumer',
        bash_command='python /opt/airflow/ingestion/consumer.py'
    )

    # 3. Transformation: dbt run
    # Runs dbt to transform Parquet data in DuckDB and write to Postgres
    dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command='cd /opt/airflow/dbt/housing_dbt && dbt run --profiles-dir . --target dev'
    )

    # 4. Governance: dbt test
    # Runs dbt tests to ensure data quality
    dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command='cd /opt/airflow/dbt/housing_dbt && dbt test --profiles-dir . --target dev'
    )

    # 5. Governance: dbt docs
    # Generates data catalog and lineage documentation
    dbt_docs = BashOperator(
        task_id='dbt_docs_generate',
        bash_command='cd /opt/airflow/dbt/housing_dbt && dbt docs generate --profiles-dir . --target dev'
    )

    # Define DAG dependencies
    run_producer >> run_consumer >> dbt_run >> dbt_test >> dbt_docs
