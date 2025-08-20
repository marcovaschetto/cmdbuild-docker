#!/bin/bash
set -e

echo "⚠️ This will stop and remove all running containers."
read -p "Are you sure? (yes/no): " confirm

if [[ "$confirm" == "yes" ]]; then
  sudo docker compose down
  echo "🛑 Environment stopped and containers removed."
else
  echo "❌ Operation cancelled."
fi