# End-to-End Housing Data Pipeline

This is a production-like Data Engineering project to process and analyze US housing prices.

## Architecture & Technology Stack

- **Ingestion**: Python scripts (Producer/Consumer) processing a local CSV file.
- **Message Broker**: Apache Kafka & ZooKeeper (handling `housing_raw` topic).
- **Data Lake (Bronze)**: MinIO (S3-compatible storage) storing raw Parquet files.
- **Processing Engine**: `dbt-duckdb` reading from MinIO, transforming, and pushing to Postgres.
- **Data Warehouse (Serving)**: PostgreSQL serving the finalized Gold layer data.
- **Orchestration**: Apache Airflow managing the DAG execution.
- **Visualization**: Metabase connected to the PostgreSQL Data Warehouse.
- **Data Catalog**: `dbt docs` served continuously on a dedicated port.
- **Infrastructure**: Fully Dockerized via Docker Compose.

---

## Directory Structure
- `airflow/`: Contains the custom Dockerfile, `requirements.txt`, and DAGs.
- `data/`: Mount point to place your `housing_data.csv`.
- `dbt/`: Contains the `dbt` project (`housing_dbt`) including models, tests, and configurations.
- `ingestion/`: Contains the Python Producer and Consumer scripts.
- `postgres-init/`: Initialization scripts for creating the required PostgreSQL databases.

---

## Setup Instructions

### 1. Place the Dataset
Download your housing CSV dataset from Kaggle and place it in the `data/` directory. **Ensure the file is named `housing_data.csv`**.

> **Note**: The dbt staging model (`stg_listings.sql`) expects columns such as `id`, `price`, `city`, `state`, `bed`, `bath`, `house_size`. If your CSV columns differ, please adjust the staging model accordingly.

### 2. Start the Infrastructure
Run the following command from the root of this project:
```bash
docker-compose up -d
```
This will start ZooKeeper, Kafka, MinIO, Postgres, Airflow components, and Metabase. Wait a couple of minutes for all services (especially Airflow initialization) to become healthy.

### 3. Access Services
- **Airflow UI**: `http://localhost:8080` (Username: `admin`, Password: `admin`)
- **MinIO UI**: `http://localhost:9001` (Username: `minioadmin`, Password: `minioadmin`)
- **Metabase UI**: `http://localhost:3000`
- **dbt Docs UI**: `http://localhost:8081` (Data Catalog & Lineage)

### 4. Run the Pipeline
1. Open the Airflow UI at `http://localhost:8080`.
2. Locate the `housing_data_pipeline` DAG.
3. Turn on the toggle switch to enable it.
4. Trigger the DAG manually by clicking the "Play" button.

### 5. Monitor Execution
The DAG will execute in this order:
1. `run_kafka_producer`: Reads the CSV and pushes messages to Kafka.
2. `run_kafka_consumer`: Consumes Kafka messages and writes to MinIO (`s3://bronze/dataset/`).
3. `dbt_run`: Uses DuckDB to read from MinIO, transform the data, and write to PostgreSQL.
4. `dbt_test`: Runs tests on the transformed models to ensure data governance.
5. `dbt_docs_generate`: Automatically builds the data catalog and lineage map.

### 6. Visualize Data
1. Open Metabase at `http://localhost:3000`.
2. Create your admin account (or log in).
3. Connect your database (if not already prompted):
   - **Database type**: PostgreSQL
   - **Name**: Data Warehouse
   - **Host**: `postgres`
   - **Port**: `5432`
   - **Database name**: `datawarehouse`
   - **Username**: `airflow`
   - **Password**: `airflow`
4. A comprehensive "US Housing Market Dashboard" has been automatically generated for you via the API script! You can view it directly by going to `http://localhost:3000/dashboard/2`.

---

## Further Reading
For a deep dive into the pipeline's concepts, technologies, and step-by-step data flow, please read the [Architecture Overview](architecture_overview.md) document.
