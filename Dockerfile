# 운영용 Dockerfile
FROM python:3.11-slim

LABEL maintainer="rookieboba <terranbin@gmail.com>" \
    version="ver 25.04.07" \
    description="FastAPI backend for production"

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all project files
COPY . .

# Expose FastAPI port
EXPOSE 8000

# Run FastAPI without reload (prod)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
