#!/bin/bash

echo "Pruning Docker system (including images)..."
docker system prune -a -f

#echo "Pruning Docker volumes..."
#docker volume prune -a

read -p "Remove all unused Docker volumes? (y/n) " ans
case "$ans" in
  y|Y)
    echo "Pruning Docker volumes..."
    docker volume prune -a -f
    ;;
  n|N)
    echo "Skipping volume prune."
    ;;
  *)
    echo "Invalid choice. Skipping volume prune."
    ;;
esac

echo "Done."