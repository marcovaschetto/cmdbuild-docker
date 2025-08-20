#!/bin/bash
set -e

echo "🚀 Starting CMDBuild Docker environment"

echo "Select environment to start:"
echo "1) Full (default)"
echo "2) Only CMDBuild"
echo "3) Only openMAINT"
echo "4) Full + Test override"
read -p "Choice [1-4]: " choice

case $choice in
  1)
    echo "▶️  Starting full stack..."
    sudo docker compose up -d
    ;;
  2)
    echo "▶️  Starting CMDBuild only..."
    sudo docker compose -f docker-compose.cmdbuild.yml up -d
    ;;
  3)
    echo "▶️  Starting openMAINT only..."
    sudo docker compose -f docker-compose.openmaint.yml up -d
    ;;
  4)
    echo "▶️  Starting full stack with test override..."
    sudo docker compose -f docker-compose.yml -f docker-compose.test.yml up -d
    ;;
  *)
    echo "❌  invalid selection. Plase select choice [1-4] to preceed"
    exit 1
    ;;
esac

echo "✅ Environment started."