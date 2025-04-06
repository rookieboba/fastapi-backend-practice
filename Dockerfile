# Python 3.11 기반 이미지 사용
FROM python:3.11-slim

# 이미지 메타 정보
LABEL maintainer="rookieboba <terranbin@gmail.com>"
LABEL version="ver 25.04.06"
LABEL description="FastAPI + Newman + Docker CLI 환경 통합 이미지"

# 시스템 패키지 설치 (시간 동기화용 패키지 포함)
RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    build-essential \
    ntp \
    tzdata \
    docker-ce-cli \
    docker-compose-plugin && \
    apt-get clean

# Node.js + newman 설치
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g newman && \
    apt-get clean

# 작업 디렉토리 설정
WORKDIR /app

# requirements 설치
COPY requirements.txt .
RUN pip install --no-cache-dir pydantic[email] && \
    pip install --no-cache-dir -r requirements.txt

# 소스 복사
COPY . .

# 포트 노출
EXPOSE 8000

# FastAPI 앱 실행
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
