import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to process S3 upload events.
    Logs the filename of uploaded objects to CloudWatch Logs.
    
    Args:
        event: S3 event notification containing bucket and object details
        context: Lambda context object
    """
    
    try:
        # Extract bucket and object information from S3 event
        records = event.get('Records', [])
        
        if not records:
            logger.warning("No records found in event")
            return {
                'statusCode': 400,
                'body': json.dumps('No records in event')
            }
        
        # Process each record (typically one per upload)
        for record in records:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            
            # Log the uploaded filename
            log_message = f"Image received: {key}"
            print(log_message)
            logger.info(log_message)
            logger.info(f"Bucket: {bucket}, Object: {key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Successfully processed S3 event')
        }
    
    except Exception as e:
        logger.error(f"Error processing S3 event: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }