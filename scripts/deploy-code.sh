#!/bin/bash

APIMRG="api-management-demo"
APIM="solarapimuat"
BLUEAPP_NAME="fx-tx-blue-app"
GREENAPP_NAME="fx-tx-green-app"

echo "Deploying code to Azure Function App (Flex Consumption)..."
echo "Checking current slot configuration..."

# Get the current slot name from APIM named value
CURRENT_SLOT=$(az apim nv show -g $APIMRG -n $APIM --named-value-id current-slot-name --query value -o tsv)

if [ -z "$CURRENT_SLOT" ]; then
    echo "ERROR: Could not retrieve current-slot-name from APIM!"
    exit 1
fi

echo "Current slot in APIM: $CURRENT_SLOT"

# Determine target deployment based on current slot
# Deploy to the opposite slot for blue-green deployment
if [ "$CURRENT_SLOT" = "green-backend" ]; then
    TARGET_APP=$BLUEAPP_NAME
    echo "Current slot is green-backend, deploying to blue app: $TARGET_APP"
else
    TARGET_APP=$GREENAPP_NAME
    echo "Current slot is blue-backend (or other), deploying to green app: $TARGET_APP"
fi
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
func azure functionapp publish $TARGET_APP --build-native-deps

echo "Deployment completed to $TARGET_APP!"
echo "Note: To switch traffic, update the 'current-slot-name' named value in APIM to point to the newly deployed backend."