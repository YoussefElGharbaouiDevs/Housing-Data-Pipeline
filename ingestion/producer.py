import os
import json
import time
import requests
import pandas as pd
from kafka import KafkaProducer

def json_serializer(data):
    return json.dumps(data).encode('utf-8')

def fetch_fred_data(series_id, api_key):
    url = f"https://api.stlouisfed.org/fred/series/observations?series_id={series_id}&api_key={api_key}&file_type=json"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        return data.get('observations', [])
    else:
        print(f"Error fetching {series_id}: {response.text}")
        return []

def main():
    kafka_broker = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'kafka:29092')
    topic_name = 'housing_raw'
    data_path = '/opt/airflow/data/realtor-data.csv' ## to be replaced with /opt/airflow/data/realtor-data.csv in production
    fred_api_key = os.getenv('FRED_API_KEY')
    
    print(f"Connecting to Kafka broker at {kafka_broker}")
    
    producer = None
    retries = 5
    while retries > 0:
        try:
            producer = KafkaProducer(
                bootstrap_servers=[kafka_broker],
                value_serializer=json_serializer
            )
            print("Successfully connected to Kafka")
            break
        except Exception as e:
            print(f"Failed to connect to Kafka: {e}. Retrying in 5 seconds...")
            retries -= 1
            time.sleep(5)
            
    if not producer:
        print("Could not connect to Kafka. Exiting.")
        return

    # 1. Fetch from FRED API
    if fred_api_key:
        series_to_fetch = ['MORTGAGE30US', 'CSUSHPINSA']
        for series_id in series_to_fetch:
            print(f"Fetching {series_id} from FRED API...")
            observations = fetch_fred_data(series_id, fred_api_key)
            for obs in observations:
                message = {
                    "source": "api",
                    "series_id": series_id,
                    "payload": obs
                }
                producer.send(topic_name, value=message)
            print(f"Sent {len(observations)} records for {series_id}")
    else:
        print("FRED_API_KEY not set. Skipping FRED API ingestion.")

    # 2. Read Dataset
    if not os.path.exists(data_path):
        print(f"Data file not found at {data_path}.")
        producer.flush()
        return

    print(f"Reading dataset from {data_path}")
    df = pd.read_csv(data_path)
    
    print(f"Sending {len(df)} dataset records to Kafka topic '{topic_name}'")
    count = 0
    for _, row in df.iterrows():
        # Clean up row dict to avoid NaN issues with JSON
        record = row.dropna().to_dict()
        message = {
            "source": "dataset",
            "payload": record
        }
        producer.send(topic_name, value=message)
        count += 1
        if count % 1000 == 0:
            print(f"Sent {count} dataset records...")
            time.sleep(0.05)
            
    producer.flush()
    print(f"Finished sending {count} dataset records to Kafka.")

if __name__ == "__main__":
    main()
