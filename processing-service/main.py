import logging
from confluent_kafka import Consumer, KafkaException, KafkaError
import influxdb_client
from influxdb_client.client.write_api import SYNCHRONOUS
import json
import uuid

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info("Starting processing-service...")

# Generate a unique consumer group ID
group_id = f"processing-service-group-{uuid.uuid4()}"

# Kafka configuration
kafka_conf = {
    'bootstrap.servers': 'kafka.zenoptics.svc.cluster.local:9092',
    'group.id': group_id,
    'auto.offset.reset': 'earliest'
}

logger.info(f"Using Kafka consumer group ID: {group_id}")

# InfluxDB configuration
influxdb_url = "http://influxdb.zenoptics.svc.cluster.local:8086"
influxdb_token = "your-influxdb-token"
influxdb_org = "your-org"
influxdb_bucket = "page_view_bucket"

# Initialize InfluxDB client
influx_client = influxdb_client.InfluxDBClient(url=influxdb_url, token=influxdb_token, org=influxdb_org)
write_api = influx_client.write_api(write_options=SYNCHRONOUS)

# Initialize Kafka consumer
consumer = Consumer(kafka_conf)
consumer.subscribe(['page_view_events'])

logger.info("Kafka consumer subscribed to topic 'page_view_events'.")

def write_to_influxdb(record):
    point = influxdb_client.Point("page_view") \
        .tag("pageName", record["pageName"]) \
        .tag("region", record["region"]) \
        .field("visits", 1) \
        .time(record["timestamp"])
    write_api.write(bucket=influxdb_bucket, org=influxdb_org, record=point)
    logger.info(f"Written to InfluxDB: {record}")

try:
    while True:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                continue
            else:
                raise KafkaException(msg.error())
        record = json.loads(msg.value().decode('utf-8'))
        logger.info(f"Consumed from Kafka: {record}")
        write_to_influxdb(record)
except KeyboardInterrupt:
    pass
finally:
    consumer.close()
    influx_client.close()
    logger.info("Kafka consumer and InfluxDB client closed.")