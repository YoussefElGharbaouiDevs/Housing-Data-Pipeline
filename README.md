# End-to-End Housing Data Pipeline

A production-like Data Engineering project designed to process, transform, and analyze US housing market data using a modern ELT architecture.

The platform simulates a real-world analytical data stack by integrating distributed ingestion, event streaming, data lake storage, orchestration, transformation, governance, and BI visualization tools.

---

# Project Overview

This project demonstrates how modern Data Engineering systems are built using industry-standard technologies.

The pipeline automates the full lifecycle of housing data:

- ingesting raw CSV data
- streaming events through Kafka
- storing raw datasets in a data lake
- transforming data using dbt
- loading analytical models into a data warehouse
- validating data quality
- generating lineage and documentation
- visualizing insights through dashboards

The objective is to replicate a production-grade analytics architecture while applying best practices in orchestration, governance, and containerization.

---

# Architecture & Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Ingestion | Python Producer/Consumer | CSV ingestion & streaming |
| Message Broker | Apache Kafka + ZooKeeper | Event streaming |
| Data Lake (Bronze) | MinIO (S3-compatible) | Raw parquet storage |
| Processing Engine | dbt + DuckDB | Data transformations |
| Data Warehouse | PostgreSQL | Analytical serving layer |
| Orchestration | Apache Airflow | DAG scheduling & automation |
| Visualization | Metabase | BI dashboards |
| Data Catalog | dbt Docs | Lineage & documentation |
| Infrastructure | Docker Compose | Containerized environment |

---

# Pipeline Architecture

```text
                    +----------------------+
                    |  Housing CSV Dataset |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    | Kafka Producer       |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    | Apache Kafka         |
                    | Topic: housing_raw   |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    | Kafka Consumer       |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    | MinIO Data Lake      |
                    | Bronze Layer         |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    | dbt + DuckDB         |
                    | Transformations      |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    | PostgreSQL Warehouse |
                    | Gold Layer           |
                    +----------+-----------+
                               |
                +--------------+--------------+
                |                             |
                v                             v
     +-------------------+       +----------------------+
     | Metabase          |       | dbt Docs & Lineage   |
     | Dashboards        |       | Data Catalog         |
     +-------------------+       +----------------------+
```

---

# Business Understanding

The real estate industry produces massive amounts of heterogeneous data that require scalable and reliable analytical infrastructures.

This project aims to simulate a modern enterprise-grade data platform capable of:

- processing housing market data end-to-end
- enabling analytical reporting
- ensuring data quality and governance
- supporting scalable transformations
- providing business-ready insights

The architecture reflects modern cloud-native ELT practices widely used in data teams today.

---

# Directory Structure

```text
.
├── airflow/
├── data/
├── dbt/
├── ingestion/
├── postgres-init/
├── docker-compose.yml
└── README.md
```

---

# Setup Instructions

## 1. Clone the Repository

```bash
git clone https://github.com/YoussefElGharbaouiDevs/Housing-Data-Pipeline.git
cd Housing-Data-Pipeline
```

## 2. Place the Dataset

Place your housing dataset inside:

```text
data/housing_data.csv
```

## 3. Start the Infrastructure

```bash
docker-compose up -d
```

---

# Access Services

| Service | URL |
|---|---|
| Airflow UI | http://localhost:8080 |
| MinIO UI | http://localhost:9001 |
| Metabase | http://localhost:3000 |
| dbt Docs | http://localhost:8081 |

---

# Author

Youssef EL Gharbaoui

Data Engineering • DataOps • Analytics Engineering • AI
