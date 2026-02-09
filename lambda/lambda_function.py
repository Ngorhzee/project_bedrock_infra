import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    # Log the entire event
    logger.info(f"Event received: {json.dumps(event)}")
    
    # Extract file information
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        logger.info(f"Image received: {key}")
        
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }