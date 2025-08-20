#!/bin/bash
set -euo pipefail

echo "🛠️ Applying configuration..."
SYS_PATH="/usr/local/tomcat/conf/cmdbuild/database.conf"
APP_PATH="/usr/local/tomcat/webapps/cmdbuild/WEB-INF/conf/database.conf"
WEBAPP_DIR="/usr/local/tomcat/webapps/cmdbuild"
CONFIGFILE="$SYS_PATH"

# Env DB
DB_HOST="${CMDBUILD_DB_HOST:-localhost}"
DB_PORT="${CMDBUILD_DB_PORT:-5432}"
DB_NAME="${CMDBUILD_DB_NAME:-cmdbuild}"
DB_USER="${CMDBUILD_DB_USER:-cmdbuild}"
DB_PASSWORD="${CMDBUILD_DB_PASSWORD:-cmdbuild}"
ADMIN_USER="${CMDBUILD_ADMIN_USERNAME:-postgres}"
ADMIN_PASSWORD="${CMDBUILD_ADMIN_PASSWORD:-postgres}"

if [ ! -f "$SYS_PATH" ]; then
  echo "📝 Generating cmdbuild database.conf..."
  mkdir -p "${SYS_PATH%/database.conf}"
  cat > "$SYS_PATH" <<EOF
db.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
db.username=${DB_USER}
db.password=${DB_PASSWORD}
db.admin.username=${ADMIN_USER}
db.admin.password=${ADMIN_PASSWORD}
db.schema=public
EOF
fi

if [ ! -f "$APP_PATH" ]; then
  mkdir -p ${APP_PATH%/database.conf}
  cp $SYS_PATH $APP_PATH
fi

#Wait for database availability
export PGPASSWORD="${DB_PASSWORD}"
until psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -c "select 1" >/dev/null 2>&1; do
  echo "⏳ Waiting for PostgreSQL ${DB_HOST}:${DB_PORT}/${DB_NAME} ..."
  sleep 2
done

TABLES=$(psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -Atc \
  "select count(*) from information_schema.tables
   where table_schema not in ('pg_catalog','information_schema');" || echo "0")

#Create database only if not exist.
if [ "${TABLES}" = "0" ]; then
  echo "🆕 First run detected → initializing schema (recreate empty)"
  bash "${WEBAPP_DIR}/cmdbuild.sh" dbconfig recreate empty -configfile "${CONFIGFILE}"
else
  #Apply pathces if database exists.
  echo "🔄 Existing DB detected → applying patches (idempotent)"
  bash "${WEBAPP_DIR}/cmdbuild.sh" dbconfig patch -configfile "${CONFIGFILE}"
fi
echo "✅ Config applied."

echo "🚀 Starting Tomcat..."
exec catalina.sh run