#!/bin/bash

echo "=== Docker Host Cleanup Script ==="
echo "This script will clean up Docker containers, images, and build files"
echo ""

# Stop and remove all containers related to abctech
echo "1. Stopping and removing abctech containers..."
sudo docker stop abctech-v1-container 2>/dev/null || echo "No abctech-v1-container to stop"
sudo docker rm abctech-v1-container 2>/dev/null || echo "No abctech-v1-container to remove"

# Remove any other containers that might be running
echo "2. Checking for other running containers..."
sudo docker ps -a

# Remove abctech images
echo "3. Removing abctech Docker images..."
sudo docker rmi abctech-app:v1 2>/dev/null || echo "No abctech-app:v1 image to remove"
sudo docker rmi thibichliennguyen/abctech-app:v1 2>/dev/null || echo "No thibichliennguyen/abctech-app:v1 image to remove"
sudo docker rmi thibichliennguyen/abctech-app:latest 2>/dev/null || echo "No thibichliennguyen/abctech-app:latest image to remove"

# Clean up any dangling images
echo "4. Removing dangling images..."
sudo docker image prune -f

# Clean up build directory
echo "5. Cleaning up build directory..."
rm -rf /home/dockeradmin/build/*
ls -la /home/dockeradmin/build/

# Show final state
echo "6. Final Docker state:"
echo "--- Running containers ---"
sudo docker ps
echo "--- All containers ---"
sudo docker ps -a
echo "--- Images ---"
sudo docker images
echo "--- Build directory ---"
ls -la /home/dockeradmin/build/

echo ""
echo "=== Cleanup Complete ==="
echo "Docker host is now clean and ready for the next task!"