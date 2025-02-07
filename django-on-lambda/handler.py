import os
from mangum import Mangum
from core.asgi import application
from django.core.management import execute_from_command_line
from django.contrib.auth import get_user_model
from django.db import connection

from aws_lambda_powertools import Logger, Tracer

logger = Logger()
tracer = Tracer()

# Create handler for Lambda
handler = Mangum(
    application,
    lifespan="off",
    api_gateway_base_path=None,
)

# Wrap handler with Powertools
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    logger.info("Event received", extra={"event": event})
    try:
        response = handler(event, context)
        logger.info("Response", extra={"response": response})
        return response
    except Exception as e:
        logger.exception("Error handling request")
        raise


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def setup_db(event, context):
    logger.info("Starting database setup")
    try:
        # Run migrations
        execute_from_command_line(['manage.py', 'migrate'])
        logger.info("Migrations completed")
        
        # Create superuser if doesn't exist
        User = get_user_model()
        username = os.environ['DJANGO_SUPERUSER_USERNAME']
        
        if not User.objects.filter(username=username).exists():
            User.objects.create_superuser(
                username=username,
                email=os.environ['DJANGO_SUPERUSER_EMAIL'],
                password=os.environ['DJANGO_SUPERUSER_PASSWORD']
            )
            logger.info(f"Superuser '{username}' created")
        else:
            logger.info(f"Superuser '{username}' already exists")
        
        return {
            'statusCode': 200,
            'body': 'Database setup completed successfully'
        }
        
    except Exception as e:
        logger.exception("Error during database setup")
        return {
            'statusCode': 500,
            'body': f'Database setup failed: {str(e)}'
        }

@logger.inject_lambda_context
@tracer.capture_lambda_handler
def check_migrations(event, context):
    logger.info("Starting migrations check")
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM django_migrations")
        return cursor.fetchall()


import json
from datetime import datetime
from django.core.serializers.json import DjangoJSONEncoder


class CustomJSONEncoder(DjangoJSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)

@logger.inject_lambda_context
@tracer.capture_lambda_handler
def check_migrations(event, context):
    logger.info("Starting migrations check")
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT app, name, applied FROM django_migrations ORDER BY applied")
            columns = [col[0] for col in cursor.description]
            migrations = [dict(zip(columns, row)) for row in cursor.fetchall()]
            
            response = {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({
                    'migrations': migrations,
                    'total_count': len(migrations)
                }, cls=CustomJSONEncoder)
            }
            
            logger.info("Migrations retrieved successfully", 
                       extra={"migration_count": len(migrations)})
            return response

    except Exception as e:
        logger.exception("Error checking migrations")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }
