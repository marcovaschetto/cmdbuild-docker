#!/bin/bash
set -e

BACKUP_DIR="/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "📦 Select what to backup:"
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

DUMP_FILE="${APP}_${TIMESTAMP}.dump"
GZ_FILE="${DUMP_FILE}.gz"
CONF_FILE="${APP}_${TIMESTAMP}.config.tar.gz"

# 1. Dump database
echo "📤 Dumping database: $DB_NAME"
PGPASSWORD=$DB_PASS pg_dump -h $DB_HOST -U $DB_USER --format=custom --file="$BACKUP_DIR/$DUMP_FILE" "$DB_NAME"

# 2. Compress
echo "📦 Compressing dump..."
gzip "$BACKUP_DIR/$DUMP_FILE"

# 3. Generate checksum
md5sum "$BACKUP_DIR/$GZ_FILE" > "$BACKUP_DIR/$GZ_FILE.md5"

# 4. Backup config
echo "🗄️ Backing up config files for $APP"
tar -czf "$BACKUP_DIR/$CONF_FILE" -C "/app/config/$APP" .
md5sum "$BACKUP_DIR/$CONF_FILE" > "$BACKUP_DIR/$CONF_FILE.md5"

echo "✅ Backup complete for $APP ($TIMESTAMP)"

echo "🧹 Cleaning up old backups for $APP..."

# Remove all backup olders than 7 days
ls -1t "$BACKUP_DIR"/${APP}_*.dump.gz | tail -n +8 | while read old_file; do
  base=$(basename "$old_file" .gz)

  # Rimuove: .dump.gz, .md5, .config.tar.gz, .config.md5
  echo "🗑️  Deleting: $base.*"
  rm -vf "$BACKUP_DIR"/"$base".dump.gz
  rm -vf "$BACKUP_DIR"/"$base".md5
  rm -vf "$BACKUP_DIR"/"$base".config.tar.gz
  rm -vf "$BACKUP_DIR"/"$base".config.md5
done

echo "✅ Retention cleanup complete (kept last 7 backups)."