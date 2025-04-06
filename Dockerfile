# -----------------------------------------
# Base: Python 3.11 on Debian Slim
# -----------------------------------------
FROM python:3.11-slim

# -----------------------------------------
#  Metadata
# -----------------------------------------
LABEL maintainer="rookieboba <terranbin@gmail.com>" \
      version="ver 25.04.06" \
      description="FastAPI backend with newman, docker cli, and API test automation environment."

# -----------------------------------------
#  System Dependencies
# -----------------------------------------
RUN apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        gnupg \
        ca-certificates \
        lsb-release \
        apt-transport-https \
        software-properties-common \
        build-essential \
        tzdata \
        ntp \
        docker-ce-cli \
        docker-compose-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------------------------
# Node.js & Newman 설치
# -----------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g newman && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------------------------
# 작업 디렉토리 설정
# -----------------------------------------
WORKDIR /app

# -----------------------------------------
# Python 패키지 설치
# -----------------------------------------
COPY requirements.txt .
RUN pip install --no-cache-dir "pydantic[email]" && \
    pip install --no-cache-dir -r requirements.txt

# -----------------------------------------
# 앱 소스 코드 복사
# -----------------------------------------
COPY . .

# -----------------------------------------
# 포트 오픈
# -----------------------------------------
EXPOSE 8000

# -----------------------------------------
# FastAPI 서버 실행
# -----------------------------------------
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
