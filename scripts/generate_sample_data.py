#!/usr/bin/env python3
"""
Sample data generator for Kafka topics used in Flink-Iceberg examples.
Generates realistic sample data for testing streaming pipelines.
"""

import json
import time
import random
from datetime import datetime, timedelta
from kafka import KafkaProducer
import argparse
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DataGenerator:
    def __init__(self, bootstrap_servers='localhost:9092'):
        """Initialize Kafka producer and data generators."""
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda x: json.dumps(x).encode('utf-8'),
            key_serializer=lambda x: str(x).encode('utf-8') if x else None
        )
        
        # Sample data pools
        self.event_types = ['login', 'logout', 'purchase', 'view_product', 'add_to_cart', 'checkout']
        self.locations = ['warehouse_1', 'warehouse_2', 'office_ny', 'office_sf', 'datacenter_east']
        self.sensor_types = ['temperature', 'humidity', 'pressure', 'cpu_usage', 'memory_usage']
        self.user_names = ['Alice Johnson', 'Bob Smith', 'Carol Brown', 'David Wilson', 'Eva Davis']
        self.user_statuses = ['active', 'inactive', 'pending', 'suspended']
        
    def generate_user_events(self, count=100, delay=1):
        """Generate user events for simple streaming example."""
        logger.info(f"Generating {count} user events with {delay}s delay...")
        
        for i in range(count):
            event = {
                'user_id': random.randint(1, 1000),
                'event_type': random.choice(self.event_types),
                'event_data': json.dumps({
                    'session_id': f"session_{random.randint(1000, 9999)}",
                    'ip_address': f"192.168.1.{random.randint(1, 254)}",
                    'user_agent': 'Mozilla/5.0 (compatible; SampleBot/1.0)'
                }),
                'event_time': datetime.now().isoformat()
            }
            
            self.producer.send('user_events', key=event['user_id'], value=event)
            
            if i % 10 == 0:
                logger.info(f"Sent {i+1}/{count} user events")
            
            time.sleep(delay)
        
        self.producer.flush()
        logger.info("User events generation completed!")
    
    def generate_metrics(self, count=200, delay=0.5):
        """Generate metrics data for windowed aggregations example."""
        logger.info(f"Generating {count} metrics with {delay}s delay...")
        
        for i in range(count):
            # Generate realistic sensor readings
            sensor_id = f"sensor_{random.randint(1, 20)}"
            metric_name = random.choice(self.sensor_types)
            
            # Generate realistic values based on metric type
            if metric_name == 'temperature':
                value = round(random.uniform(15.0, 35.0), 2)
            elif metric_name == 'humidity':
                value = round(random.uniform(30.0, 90.0), 2)
            elif metric_name == 'pressure':
                value = round(random.uniform(990.0, 1020.0), 2)
            elif metric_name in ['cpu_usage', 'memory_usage']:
                value = round(random.uniform(0.0, 100.0), 2)
            else:
                value = round(random.uniform(0.0, 100.0), 2)
            
            event = {
                'sensor_id': sensor_id,
                'metric_name': metric_name,
                'metric_value': value,
                'location': random.choice(self.locations),
                'event_time': datetime.now().isoformat()
            }
            
            self.producer.send('metrics', key=sensor_id, value=event)
            
            if i % 20 == 0:
                logger.info(f"Sent {i+1}/{count} metrics")
            
            time.sleep(delay)
        
        self.producer.flush()
        logger.info("Metrics generation completed!")
    
    def generate_cdc_events(self, count=50, delay=2):
        """Generate CDC events for change data capture example."""
        logger.info(f"Generating {count} CDC events with {delay}s delay...")
        
        # Maintain state of users for realistic CDC
        users = {}
        
        for i in range(count):
            user_id = random.randint(1, 20)
            op_type = random.choices(['INSERT', 'UPDATE', 'DELETE'], weights=[30, 60, 10])[0]
            
            event = {
                'op_type': op_type,
                'ts_ms': int(time.time() * 1000)
            }
            
            if op_type == 'INSERT':
                # New user
                after_data = {
                    'id': user_id,
                    'name': random.choice(self.user_names),
                    'email': f"user{user_id}@example.com",
                    'status': random.choice(self.user_statuses),
                    'updated_at': datetime.now().isoformat()
                }
                users[user_id] = after_data
                event['before'] = None
                event['after'] = after_data
                
            elif op_type == 'UPDATE' and user_id in users:
                # Update existing user
                before_data = users[user_id].copy()
                after_data = before_data.copy()
                
                # Randomly update fields
                if random.random() < 0.5:
                    after_data['status'] = random.choice(self.user_statuses)
                if random.random() < 0.3:
                    after_data['name'] = random.choice(self.user_names)
                
                after_data['updated_at'] = datetime.now().isoformat()
                users[user_id] = after_data
                
                event['before'] = before_data
                event['after'] = after_data
                
            elif op_type == 'DELETE' and user_id in users:
                # Delete user
                before_data = users[user_id]
                del users[user_id]
                
                event['before'] = before_data
                event['after'] = None
            else:
                continue  # Skip if no valid operation
            
            self.producer.send('cdc_users', key=user_id, value=event)
            
            if i % 5 == 0:
                logger.info(f"Sent {i+1}/{count} CDC events")
            
            time.sleep(delay)
        
        self.producer.flush()
        logger.info("CDC events generation completed!")
    
    def close(self):
        """Close the Kafka producer."""
        self.producer.close()

def main():
    parser = argparse.ArgumentParser(description='Generate sample data for Flink-Iceberg examples')
    parser.add_argument('--bootstrap-servers', default='localhost:9092', 
                       help='Kafka bootstrap servers (default: localhost:9092)')
    parser.add_argument('--data-type', choices=['user_events', 'metrics', 'cdc', 'all'], 
                       default='all', help='Type of data to generate')
    parser.add_argument('--count', type=int, default=100, 
                       help='Number of events to generate (default: 100)')
    parser.add_argument('--delay', type=float, default=1.0, 
                       help='Delay between events in seconds (default: 1.0)')
    
    args = parser.parse_args()
    
    generator = DataGenerator(args.bootstrap_servers)
    
    try:
        if args.data_type == 'user_events':
            generator.generate_user_events(args.count, args.delay)
        elif args.data_type == 'metrics':
            generator.generate_metrics(args.count, args.delay)
        elif args.data_type == 'cdc':
            generator.generate_cdc_events(args.count, args.delay)
        elif args.data_type == 'all':
            logger.info("Generating all types of sample data...")
            generator.generate_user_events(50, 0.5)
            time.sleep(2)
            generator.generate_metrics(100, 0.3)
            time.sleep(2)
            generator.generate_cdc_events(30, 1.0)
    
    except KeyboardInterrupt:
        logger.info("Data generation interrupted by user")
    except Exception as e:
        logger.error(f"Error generating data: {e}")
    finally:
        generator.close()

if __name__ == '__main__':
    main()