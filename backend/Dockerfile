# Author: Domonick Mack
# Date: 2026-11-09
# Description: Production Dockerfile for the Django REST Framework + PyMongo sync and download server.

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_DEBUG=False

WORKDIR /app

# Install system dependencies for healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

COPY . /app/

RUN mkdir -p /app/releases

EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate --noinput && gunicorn notes_backend.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 60"]
