#!/usr/bin/env bash
set -e

echo "🔧 Initializing cmdbuild and openmaint databases..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE ROLE ${CMDBUILD_DB_USER} LOGIN PASSWORD '${CMDBUILD_DB_PASSWORD}';
  CREATE DATABASE ${CMDBUILD_DB_NAME} OWNER ${CMDBUILD_DB_USER};
  GRANT ALL PRIVILEGES ON DATABASE ${CMDBUILD_DB_NAME} TO ${CMDBUILD_DB_USER};
EOSQL

echo "✅ Database users and schemas initialized."