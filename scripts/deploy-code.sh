#!/bin/bash

echo "Deploying code to Azure Function App (Flex Consumption)..."
echo "Current directory: $(pwd)"

echo "Checking build artifacts..."
ls -la

# Verify required files exist
if [ ! -f "transaction-api" ]; then
    echo "ERROR: transaction-api executable not found!"
    exit 1
fi

if [ ! -f "host.json" ]; then
    echo "ERROR: host.json not found!"
    exit 1
fi

if [ ! -f "transaction/function.json" ]; then
    echo "ERROR: function.json not found in transaction directory!"
    exit 1
fi

echo "All required files found. Proceeding with deployment..."

# Set executable permissions
chmod +x transaction-api

echo "Deploying Function App to Azure..."
func azure functionapp publish fx-tx-blue-app --build-native-deps

echo "Deployment completed!"