import os
import json
import time
import pandas as pd
from kafka import KafkaConsumer
from datetime import datetime
import pyarrow as pa
import pyarrow.parquet as pq
import s3fs

def json_deserializer(data):
    try:
        return json.loads(data.decode('utf-8'))
    except:
        return None

def main():
    kafka_broker = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'kafka:29092')
    topic_name = 'housing_raw'
    
    # MinIO settings
    minio_endpoint = os.getenv('MINIO_ENDPOINT', 'minio:9000')
    minio_access_key = os.getenv('MINIO_ACCESS_KEY', 'minioadmin')
    minio_secret_key = os.getenv('MINIO_SECRET_KEY', 'minioadmin')
    
    print(f"Connecting to Kafka broker at {kafka_broker}")
    
    consumer = KafkaConsumer(
        topic_name,
        bootstrap_servers=[kafka_broker],
        auto_offset_reset='earliest',
        enable_auto_commit=False,
        group_id='housing_consumer_group_v2',
        value_deserializer=json_deserializer,
        consumer_timeout_ms=10000 # Stop iterating if no message after 10 seconds
    )
    
    dataset_records = []
    api_records = []
    print("Listening for messages...")
    
    # Consume messages
    for message in consumer:
        val = message.value
        if val and isinstance(val, dict):
            if val.get("source") == "dataset":
                dataset_records.append(val.get("payload", {}))
            elif val.get("source") == "api":
                # Flatten the payload a bit for easier querying later
                payload = val.get("payload", {})
                payload["series_id"] = val.get("series_id")
                api_records.append(payload)
            else:
                # Fallback for old messages without source wrapper
                dataset_records.append(val)
                
    print(f"Consumed {len(dataset_records)} dataset records and {len(api_records)} API records.")
    
    fs = s3fs.S3FileSystem(
        client_kwargs={'endpoint_url': f'http://{minio_endpoint}'},
        key=minio_access_key,
        secret=minio_secret_key
    )
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Write Dataset to MinIO
    if len(dataset_records) > 0:
        print("Writing dataset to MinIO...")
        df_dataset = pd.DataFrame(dataset_records)
        s3_path_dataset = f"bronze/dataset/housing_{timestamp}.parquet"
        table_dataset = pa.Table.from_pandas(df_dataset)
        pq.write_table(table_dataset, s3_path_dataset, filesystem=fs)
        print(f"Successfully wrote {len(dataset_records)} dataset records to s3://{s3_path_dataset}")
    else:
        print("No dataset records to write.")
        
    # Write API data to MinIO
    if len(api_records) > 0:
        print("Writing API data to MinIO...")
        df_api = pd.DataFrame(api_records)
        s3_path_api = f"bronze/api/fred_{timestamp}.parquet"
        table_api = pa.Table.from_pandas(df_api)
        pq.write_table(table_api, s3_path_api, filesystem=fs)
        print(f"Successfully wrote {len(api_records)} API records to s3://{s3_path_api}")
    else:
        print("No API records to write.")
    consumer.commit()
    consumer.close()

if __name__ == "__main__":
    main()
