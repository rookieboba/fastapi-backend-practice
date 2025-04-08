# 운영용 FastAPI Dockerfile
FROM python:3.11-slim

LABEL maintainer="rookieboba <terranbin@gmail.com>" \
    version="ver 25.04.08" \
    description="FastAPI backend for production"

# 타임존 설정
RUN apt-get update && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 설정
WORKDIR /app

# 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 복사
COPY . .

# 포트 오픈
EXPOSE 8000

# 운영 실행 커맨드
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
