#!/bin/bash
set -e

BACKUP_DIR="/backup"

echo "🔄 Select database to restore:"
echo "1) CMDBuild"
echo "2) openMAINT"
read -p "Choice [1-2]: " APP_CHOICE

if [[ "$APP_CHOICE" == "1" ]]; then
  APP="cmdbuild"
  DB_NAME=$CMDBUILD_DB_NAME
  DB_USER=$CMDBUILD_DB_USER
  DB_PASS=$CMDBUILD_DB_PASSWORD
  DB_HOST=$CMDBUILD_DB_HOST
elif [[ "$APP_CHOICE" == "2" ]]; then
  APP="openmaint"
  DB_NAME=$OPENMAINT_DB_NAME
  DB_USER=$OPENMAINT_DB_USER
  DB_PASS=$OPENMAINT_DB_PASSWORD
  DB_HOST=$OPENMAINT_DB_HOST
else
  echo "❌ Invalid choice."
  exit 1
fi

echo "📁 Available backups for $APP:"
ls "$BACKUP_DIR" | grep "^${APP}_.*\.dump\.gz" || { echo "❌ No backups found."; exit 1; }

read -p "🗃️ Enter filename to restore (e.g. ${APP}_20250819_101530.dump.gz): " GZ_FILE
GZ_PATH="$BACKUP_DIR/$GZ_FILE"
CHECKSUM_PATH="$GZ_PATH.md5"

if [[ ! -f "$GZ_PATH" ]]; then
  echo "❌ File not found: $GZ_PATH"
  exit 1
fi

if [[ -f "$CHECKSUM_PATH" ]]; then
  echo "🔐 Verifying checksum..."
  cd $BACKUP_DIR && md5sum -c "$(basename $CHECKSUM_PATH)"
else
  echo "⚠️ Checksum not found, skipping verification."
fi

# Confirm destructive operation
echo "⚠️ This will DROP and recreate the DB: $DB_NAME"
read -p "Type YES to confirm: " confirm
[[ "$confirm" != "YES" ]] && { echo "❌ Cancelled."; exit 1; }

# Decompress
echo "📂 Decompressing..."
gunzip -fk "$GZ_PATH"
DUMP_PATH="${GZ_PATH%.gz}"

# Drop + recreate DB
echo "🗑️ Dropping existing DB..."
PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -c "DROP DATABASE IF EXISTS $DB_NAME;"
PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -c "CREATE DATABASE $DB_NAME;"

# Restore
echo "♻️ Restoring $DUMP_PATH into $DB_NAME"
PGPASSWORD=$DB_PASS pg_restore -h $DB_HOST -U $DB_USER -d $DB_NAME "$DUMP_PATH"

rm -f "$DUMP_PATH"
echo "✅ Restore complete."