#!/usr/bin/env bash
set -e

echo "🔧 Initializing cmdbuild and openmaint databases..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE ROLE ${OPENMAINT_DB_USER} LOGIN PASSWORD '${OPENMAINT_DB_PASSWORD}';
  CREATE DATABASE ${OPENMAINT_DB_NAME} OWNER ${OPENMAINT_DB_USER};
  GRANT ALL PRIVILEGES ON DATABASE ${OPENMAINT_DB_NAME} TO ${OPENMAINT_DB_USER};
EOSQL

echo "✅ Database users and schemas initialized."