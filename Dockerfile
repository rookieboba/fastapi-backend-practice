# 베이스 이미지: Python + 빌드도구 설치 가능한 Debian 기반
FROM python:3.11-slim

# 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    git \
    curl \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    build-essential \
    && apt-get clean

# 작업 디렉토리 설정
WORKDIR /app

# requirements.txt 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir pydantic[email] && \
    pip install --no-cache-dir -r requirements.txt

# FastAPI 앱 복사
COPY . .

# Docker CLI 설치
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg && \
    echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-compose-plugin && \
    apt-get clean

# Node.js + npm 설치 (newman 용)
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g newman

# 포트 오픈
EXPOSE 8000

# FastAPI 실행
CMD ["uvicorn", "Pydantic:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

