# Base image: Python 3.11 on Debian Slim
FROM python:3.11-slim

# Metadata
LABEL maintainer="rookieboba <terranbin@gmail.com>" \
      version="ver 25.04.06" \
      description="FastAPI backend with Docker CLI and newman test environment"

# Avoid APT release timestamp errors
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99ignore-release-date

# Install basic time-related packages first
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata \
        ntp && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install tools required to add Docker repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        gnupg \
        lsb-release && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Add Docker APT repository
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

# Install core system packages including Docker CLI
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        build-essential \
        docker-ce-cli \
        docker-compose-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js and newman
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g newman && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir "pydantic[email]" && \
    pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Expose FastAPI default port
EXPOSE 8000

# Start FastAPI server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

