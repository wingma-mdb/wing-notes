#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== 1. Checking GPG version ==="
gpg --version

echo "=== 2. Adding MongoDB GPG key ==="
wget -qO- https://www.mongodb.org/static/pgp/server-8.0.asc | tee /etc/apt/trusted.gpg.d/server-8.0.asc > /dev/null

echo "=== 3. Checking OS version ==="
cat /etc/os-release

echo "=== 4. Adding MongoDB repository ==="
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list > /dev/null

echo "=== 5. Updating package lists ==="
apt update

echo "=== 6. Installing MongoDB Shell (mongosh) ==="
apt install -y mongodb-mongosh

echo "=== 7. Verifying mongosh installation ==="
mongosh --version

echo "=== Installation complete! ==="
