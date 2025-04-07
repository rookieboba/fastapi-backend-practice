# Base image
FROM python:3.11-slim

LABEL maintainer="rookieboba <terranbin@gmail.com>" \
      version="ver 25.04.07" \
      description="FastAPI backend for production"

RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

