# CentOS가 아닌 Python 전용 base image 사용
FROM python:3.11-slim

# 시스템 패키지 설치 (선택: git, curl 등)
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean

# 작업 디렉토리 설정
WORKDIR /app

# requirements.txt 먼저 복사하고 설치
COPY requirements.txt .

# pydantic[email] 포함하여 설치 (email-validator 포함)
RUN pip install --no-cache-dir pydantic[email] && \
    pip install --no-cache-dir -r requirements.txt

# 애플리케이션 소스 복사
COPY . .

# 포트 개방
EXPOSE 8000

# FastAPI 앱 실행
CMD ["uvicorn", "Pydantic:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

