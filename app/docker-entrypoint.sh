#!/bin/bash
set -e

# DB가 없으면 초기화
if [ ! -f "/data/db.sqlite3" ]; then
    echo "[INFO] DB 파일이 없으므로 초기화합니다."
    sqlite3 /data/db.sqlite3 < /app/sqlite3/01_create_users_table.sql
fi

# FastAPI 실행
exec "$@"
