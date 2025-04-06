# 베이스 이미지
FROM python:3.11-slim

# 작업 디렉토리 설정
WORKDIR /app

# 의존성 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스코드 복사
COPY . .

# 환경변수 로딩을 위한 python-dotenv 설치 (선택사항)
RUN pip install python-dotenv

# 기본 포트 설정
EXPOSE 8000

# FastAPI 서버 실행
CMD ["uvicorn", "Pydantic:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
