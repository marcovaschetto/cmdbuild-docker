#!/bin/bash
set -e

# Set cron expression from env
if [ -z "$BACKUP_SCHEDULE_CRON" ]; then
  echo "⚠️ BACKUP_SCHEDULE_CRON not set. Using default: '0 2 * * *'"
  BACKUP_SCHEDULE_CRON="0 2 * * *"
fi

# Replace template with actual cron expression
CRON_FILE="/etc/crontabs/root"
CRON_TEMPLATE="/cron/crontab.template"

sed "s|{{CRON_EXPRESSION}}|$BACKUP_SCHEDULE_CRON|" "$CRON_TEMPLATE" > "$CRON_FILE"
echo "🕒 Installed CRON schedule: $BACKUP_SCHEDULE_CRON"

# Start cron daemon
echo "🚀 Starting cron daemon..."
crond -f -l 8 &
CRON_PID=$!

# Keep container running with logs
tail -f /var/log/cron.log &
TAIL_PID=$!

wait $TAIL_PID $CRON_PID