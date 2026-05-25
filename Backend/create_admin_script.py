#!/usr/bin/env python
import os
import sys
import django

sys.path.insert(0, '/app/narinocultura_backend/narinocultura_backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.users.models import User

user, created = User.objects.get_or_create(
    email='admin@narino.local',
    defaults={
        'first_name': 'Admin',
        'last_name': 'User',
        'role': 'ADMINISTRADOR',
        'is_verified': True,
        'is_active': True,
        'is_staff': True
    }
)
user.set_password('AdminPass123!')
user.save()

if created:
    print(f'✅ Admin created: {user.email}')
else:
    print(f'⚠️ Admin already exists: {user.email}')
