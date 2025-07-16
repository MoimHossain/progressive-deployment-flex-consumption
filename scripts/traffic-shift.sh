#!/bin/bash

APIMRG="api-management-demo"
APIM="solarapimuat"
BLUEAPP_NAME="fx-tx-blue-app"
GREENAPP_NAME="fx-tx-green-app"
BACKEND_POOL="green-blue-pool"
BLUE_BACKEND="blue-backend"
GREEN_BACKEND="green-backend"

echo "Starting traffic shift process..."
echo "APIM: $APIM in Resource Group: $APIMRG"

# Get the current slot name from APIM named value
echo "Reading current slot configuration from APIM..."
CURRENT_SLOT=$(az apim nv show -g $APIMRG -n $APIM --named-value-id current-slot-name --query value -o tsv)

if [ -z "$CURRENT_SLOT" ]; then
    echo "ERROR: Could not retrieve current-slot-name from APIM!"
    exit 1
fi

echo "Current active slot: $CURRENT_SLOT"

# Determine traffic weights based on current slot
if [ "$CURRENT_SLOT" = "green-backend" ]; then
    # Current is green, so shift more traffic to blue (new deployment)
    BLUE_WEIGHT=10
    GREEN_WEIGHT=90
    echo "Current slot is green-backend, shifting 10% traffic to blue-backend"
else
    # Current is blue, so shift more traffic to green (new deployment)
    BLUE_WEIGHT=90
    GREEN_WEIGHT=10
    echo "Current slot is blue-backend, shifting 10% traffic to green-backend"
fi

echo "Setting backend pool weights - Blue: $BLUE_WEIGHT%, Green: $GREEN_WEIGHT%"

# Update the backend pool with new weights
echo "Updating backend pool weights..."

# Update blue backend weight in the pool
az apim backend update \
    -g $APIMRG \
    -n $APIM \
    --backend-id $BACKEND_POOL \
    --set "pool.backends[?backendId=='$BLUE_BACKEND'].weight=$BLUE_WEIGHT"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to update blue backend weight!"
    exit 1
fi

# Update green backend weight in the pool
az apim backend update \
    -g $APIMRG \
    -n $APIM \
    --backend-id $BACKEND_POOL \
    --set "pool.backends[?backendId=='$GREEN_BACKEND'].weight=$GREEN_WEIGHT"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to update green backend weight!"
    exit 1
fi

echo "Traffic shift completed successfully!"
echo "Current weights: Blue=$BLUE_WEIGHT%, Green=$GREEN_WEIGHT%"
echo ""
echo "To verify the changes, run:"
echo "az apim backend show -g $APIMRG -n $APIM --backend-id $BACKEND_POOL --query 'pool.backends[].{backend:backendId,weight:weight}' -o table"