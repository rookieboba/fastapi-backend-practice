#!/bin/bash
set -e

DB_FILE="/data/db.sqlite3"
SQL_DIR="/app/sqlite3"

# 1. DB가 없을 경우에만 초기화
if [ ! -f "$DB_FILE" ]; then
    echo "[INFO] DB 파일이 없으므로 초기화합니다: $DB_FILE"

    for sql_file in "$SQL_DIR"/*.sql; do
        echo "[INFO] 실행 중: $sql_file"
        sqlite3 "$DB_FILE" < "$sql_file"
    done

    echo "[INFO] DB 초기화 완료"
else
    echo "[INFO] 기존 DB가 존재하므로 초기화 생략"
fi

# 2. FastAPI 앱 실행 (Dockerfile CMD에서 넘겨줌)
exec "$@"
