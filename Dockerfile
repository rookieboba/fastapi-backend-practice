# Base image
FROM python:3.11-slim

# Metadata
LABEL maintainer="rookieboba <terranbin@gmail.com>" \
      version="ver 25.04.07" \
      description="FastAPI backend with Docker CLI and newman test environment"

# Prevent APT release timestamp issues
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99ignore-release-date

# Install timezone & NTP packages (non-interactive)
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata \
        ntp && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install tools for Docker APT repository
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

# Install Docker CLI, compose plugin, and development tools
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

# Install Node.js 20 and Newman (global)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g newman && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port for FastAPI
EXPOSE 8000

# Run FastAPI app with uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
