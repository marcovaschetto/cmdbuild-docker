#!/bin/bash
set -euo pipefail

echo "🛠️ Applying configuration..."
SYS_PATH="/usr/local/tomcat/conf/openmaint/database.conf"
APP_PATH="/usr/local/tomcat/webapps/openmaint/WEB-INF/conf/database.conf"
WEBAPP_DIR="/usr/local/tomcat/webapps/openmaint"
CONFIGFILE="$SYS_PATH"

# Env DB
DB_HOST="${OPENMAINT_DB_HOST:-localhost}"
DB_PORT="${OPENMAINT_DB_PORT:-5432}"
DB_NAME="${OPENMAINT_DB_NAME:-openmaint}"
DB_USER="${OPENMAINT_DB_USER:-openmaint}"
DB_PASSWORD="${OPENMAINT_DB_PASSWORD:-openmaint}"
ADMIN_USER="${OPENMAINT_ADMIN_USERNAME:-postgres}"
ADMIN_PASSWORD="${OPENMAINT_ADMIN_PASSWORD:-postgres}"

if [ ! -f "$SYS_PATH" ]; then
  echo "📝 Generating openmaint database.conf..."
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

#Create database if not exist at first run
if [ "${TABLES}" = "0" ]; then
  echo "🆕 First run detected → initializing schema (recreate empty)"
  bash "${WEBAPP_DIR}/cmdbuild.sh" dbconfig recreate empty -configfile "${CONFIGFILE}"
else
  #Apply pathces if database exists and application version has changed.
  echo "🔄 Existing DB detected → applying patches (idempotent)"
  bash "${WEBAPP_DIR}/cmdbuild.sh" dbconfig patch -configfile "${CONFIGFILE}"
fi
echo "✅ Config applied."

echo "🚀 Starting Tomcat..."
exec catalina.sh run