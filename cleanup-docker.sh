#!/bin/bash

echo "Pruning Docker system (including images)..."
docker system prune -a -f

echo "Pruning Docker volumes..."
docker volume prune -f

echo "Done."