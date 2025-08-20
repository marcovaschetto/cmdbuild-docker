#!/bin/bash

set -e

echo "🚀 Initializing CMDBuild Docker environment..."

# Check for .env.example
if [ ! -f ".env.example" ]; then
  echo "❌ .env.example not found. Cannot proceed."
  exit 1
fi

# Warn if .env already exists
if [ -f ".env" ]; then
  echo "⚠️  WARNING: .env file already exists."
  echo "⚠️  Re-initializing this file is NOT reversible."
  echo "⚠️  If you continue, existing databases and volumes must be destroyed and rebuilt from scratch!"
  echo ""
  read -p "❓ Are you absolutely sure you want to proceed? (yes/no): " confirm

  if [[ "$confirm" != "yes" ]]; then
    echo "❌ Aborted. Existing .env preserved."
    exit 0
  fi

  echo "🔁 Overwriting existing .env..."
fi

# Generate random passwords
CMDBUILD_PASS=$(openssl rand -base64 24)
OPENMAINT_PASS=$(openssl rand -base64 24)
CMDBUILD_ADMIN_PASS=$(openssl rand -base64 24)
OPENMAINT_ADMIN_PASS=$(openssl rand -base64 24)

echo "🔐 Generated random database passwords."

echo ""
echo "📦 Select automatic backup frequency:"
echo "1) Every 12 hours       →  0 */12 * * *"
echo "2) Every 24 hours       →  0 2 * * *"
echo "3) Every 7 days         →  0 3 */7 * *"
echo "4) Every 30 days        →  0 4 1 * *"
read -p "Select option [1-4]: " backup_choice

case "$backup_choice" in
  1) BACKUP_SCHEDULE_CRON="0 */12 * * *" ;;
  2) BACKUP_SCHEDULE_CRON="0 2 * * *" ;;
  3) BACKUP_SCHEDULE_CRON="0 3 */7 * *" ;;
  4) BACKUP_SCHEDULE_CRON="0 4 1 * *" ;;
  *) 
    echo "❌ Invalid option. Defaulting to 24h."
    BACKUP_SCHEDULE_CRON="0 2 * * *"
    ;;
esac

echo "✅ .env created and updated with secure credentials and desired backup time."
# Copy and patch .env
cp .env.example .env

# Replace default passwords with generated ones
sed -i "s|CMDBUILD_DB_PASSWORD=.*|CMDBUILD_DB_PASSWORD=$CMDBUILD_PASS|" .env
sed -i "s|OPENMAINT_DB_PASSWORD=.*|OPENMAINT_DB_PASSWORD=$OPENMAINT_PASS|" .env
sed -i "s|BACKUP_SCHEDULE_CRON=.*|BACKUP_SCHEDULE_CRON=$BACKUP_SCHEDULE_CRON|" .env
sed -i "s|CMDBUILD_ADMIN_PASSWORD=.*|CMDBUILD_ADMIN_PASSWORD=$CMDBUILD_ADMIN_PASS|" .env
sed -i "s|OPENMAINT_ADMIN_PASSWORD=.*|OPENMAINT_ADMIN_PASSWORD=$OPENMAINT_ADMIN_PASS|" .env

echo "✅ Initialization complete."

echo ""
echo "✅ Backup CRON schedule set to: $BACKUP_SCHEDULE_CRON"
echo "📘 To change it manually, edit the '.env' file and update:"
echo "    BACKUP_SCHEDULE_CRON=\"<cron_expression>\""
echo ""
echo "📚 Cron format: (minute hour day month day-of-week)"
echo "           # ┌──────────── min (0 - 59)"
echo "           # │ ┌────────── hour (0 - 23)"
echo "           # │ │ ┌──────── day of month (1 - 31)"
echo "           # │ │ │ ┌────── month (1 - 12)"
echo "           # │ │ │ │ ┌──── day of week (0 - 6) (Sunday = 0)"
echo "           # │ │ │ │ │"
echo "           # │ │ │ │ │"
echo "           # * * * * *"
echo "    Example: 0 2 * * *  → every day at 2:00 AM"