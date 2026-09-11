#!/bin/bash

# Exit immediately if a command fails
set -e

echo "=== 1. Checking Homebrew installation ==="
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is not installed. Please install Homebrew first from https://brew.sh/"
    exit 1
fi

echo "=== 2. Tapping MongoDB repository ==="
brew tap mongodb/brew

echo "=== 3. Trusting MongoDB tap ==="
brew trust mongodb/brew

echo "=== 4. Installing mongosh ==="
brew install mongodb/brew/mongosh

echo "=== 5. Verifying installation ==="
mongosh --version

echo "=== Mongosh installation complete! ==="
