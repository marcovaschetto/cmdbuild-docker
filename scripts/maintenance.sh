#!/bin/bash
set -e

show_menu() {
  echo "🛠️ CMDBuild Docker Maintenance Menu"
  echo "1) Show container status"
  echo "2) Show live logs"
  echo "3) Run backup now"
  echo "4) Cleanup unused Docker resources"
  echo "5) List available backups"
  echo "6) Restore database from backup"
  echo "7) Show automatic backup log"
  echo "0) Exit"
}

run_backup() {
  sudo docker exec -it backup /bin/bash /backup/backup.sh
}

list_backups() {
  echo "🔍 Select backup type:"
  echo "1) CMDBuild"
  echo "2) openMAINT"
  read -p "Choice [1-2]: " APP_CHOICE

  if [[ "$APP_CHOICE" == "1" ]]; then
    APP="cmdbuild"
  elif [[ "$APP_CHOICE" == "2" ]]; then
    APP="openmaint"
  else
    echo "❌ Invalid choice."
    return
  fi

  echo "📁 Available backups for $APP:"
  ls volumes/backup | grep "^${APP}_.*\.dump\.gz" || echo "⚠️ No backups found."
}

run_restore() {
  echo "🔁 Starting guided restore..."
  sudo docker exec -it backup /bin/bash /backup/restore.sh
}

show_cron_log() {
  echo "📋 Last 30 lines of automatic backup cron log:"
  sudo docker exec -it backup tail -n 30 /var/log/cron.log || echo "⚠️ Cron log not available."
}

cleanup_docker() {
  echo "⚠️ WARNING: This will remove unused containers, images, volumes."
  read -p "Are you sure? Type YES to continue: " confirm
  [[ "$confirm" != "YES" ]] && { echo "❌ Cancelled."; return; }
  sudo docker system prune -af --volumes
  sudo docker volume ls -q | grep cmdbuild | xargs -r sudo docker volume rm
  exit 0
}

while true; do
  echo
  show_menu
  read -p "➡️ Select option [0-6]: " choice
  echo

  case $choice in
    1) sudo docker ps -a ;;
    2) sudo docker compose logs --tail=100 -f ;;
    3) run_backup ;;
    4) cleanup_docker ;;
    5) list_backups ;;
    6) run_restore ;;
    7) show_cron_log ;;
    0) echo "👋 Goodbye!"; exit 0 ;;
    *) echo "❌ Invalid option." ;;
  esac
done