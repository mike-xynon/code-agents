# Dashboard Container
# Flask-based web UI for managing Claude workers

FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir \
    flask \
    docker \
    redis \
    gunicorn \
    requests

# Copy application files
COPY app.py /app/
COPY templates /app/templates/

# Expose Flask port
EXPOSE 5000

# Environment variables
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV DOCKER_HOST=unix:///var/run/docker.sock

# Run with gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "4", "app:app"]
