#!/bin/bash
set -e

MODULES=("cmdbuild-app" "openmaint-app" "backup")
USERNAME="marcovaschetto"
VERSION=latest

show_menu() {
  echo "🛠️ Docker build and push Menu"
  echo "1) Build only"
  echo "2) Push only"
  echo "3) Build & Push"
}

build_image() {
  echo "🚀 Starting Docker build under: $USERNAME"
  for mod in "${MODULES[@]}"; do
    TAG="$USERNAME/${mod}:${VERSION}"
    echo "🔨 Building image: $TAG"
    sudo docker build -t "$TAG" "./docker/$mod"
  done
  echo "✅ Done: All images built"
}
push_image()  {
  echo "🚀 Starting Docker push under: $USERNAME"
  for mod in "${MODULES[@]}"; do
    TAG="$USERNAME/${mod}:${VERSION}"
    echo "📤 Pushing image to Docker Hub..."
    sudo docker push "$TAG"
  done
  echo "✅ Done: All images pushed"
}

echo
if [ $1 ]; then
  choice=$1
else
  show_menu
  read -p "➡️ Select option [1-3]: " choice
fi
echo

case $choice in
    1) build_image ;;
    2) push_image ;;
    3) build_image && push_image ;;
    *) echo "❌ Invalid option." ;;
  esac