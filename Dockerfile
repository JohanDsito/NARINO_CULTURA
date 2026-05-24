FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt /app/

# Install dependencies
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy the entire project
COPY . /app/

EXPOSE 8000

# Default command for Django service
CMD ["sh", "-c", "cd /app/narinocultura_backend && python manage.py migrate && python manage.py seed_music_genres && python manage.py create_admin && python -m daphne -b 0.0.0.0 -p 8000 config.asgi:application"]
