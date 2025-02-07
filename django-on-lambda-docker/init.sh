#!/bin/sh

# Run migrations
python manage.py migrate

# Create superuser if not exists
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='${DJANGO_SUPERUSER_USERNAME:-admin}').exists():
    User.objects.create_superuser('${DJANGO_SUPERUSER_USERNAME:-admin}', 
                                '${DJANGO_SUPERUSER_EMAIL:-admin@example.com}', 
                                '${DJANGO_SUPERUSER_PASSWORD:-admin}')
EOF

# Execute the main command
exec "$@"

