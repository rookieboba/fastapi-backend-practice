# Base image
FROM python:3.11-slim

LABEL maintainer="rookieboba <terranbin@gmail.com>" \
    version="ver 25.04.07" \
    description="FastAPI backend for production"

# Install necessary system dependencies including sqlite3 and procps (for ps command)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata \
    sqlite3 \
    procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Expose port for FastAPI
EXPOSE 8000

# Start the FastAPI app with uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]