#!/bin/bash

# Check if trafficPercentage parameter is provided
if [ -z "$1" ]; then
    echo "ERROR: trafficPercentage parameter is required!"
    echo "Usage: $0 <trafficPercentage>"
    echo "Example: $0 10    # Shifts 10% traffic to the new deployment"
    echo "Example: $0 30    # Shifts 30% traffic to the new deployment"
    echo "Example: $0 50    # Shifts 50% traffic to the new deployment"
    echo "Example: $0 100   # Shifts 100% traffic to the new deployment"
    exit 1
fi

TRAFFIC_PERCENTAGE=$1

# Validate traffic percentage is a number between 0 and 100
if ! [[ "$TRAFFIC_PERCENTAGE" =~ ^[0-9]+$ ]] || [ "$TRAFFIC_PERCENTAGE" -lt 0 ] || [ "$TRAFFIC_PERCENTAGE" -gt 100 ]; then
    echo "ERROR: trafficPercentage must be a number between 0 and 100!"
    echo "Provided value: $TRAFFIC_PERCENTAGE"
    exit 1
fi

# Calculate remainder percentage
REMAINDER_PERCENTAGE=$((100 - TRAFFIC_PERCENTAGE))

APIMRG="api-management-demo"
APIM="solarapimuat"
BLUEAPP_NAME="fx-tx-blue-app"
GREENAPP_NAME="fx-tx-green-app"
BACKEND_POOL="green-blue-pool"
BLUE_BACKEND="blue-backend"
GREEN_BACKEND="green-backend"

echo "Starting traffic shift process..."
echo "APIM: $APIM in Resource Group: $APIMRG"
echo "Traffic percentage to shift: $TRAFFIC_PERCENTAGE%"
echo "Remainder percentage: $REMAINDER_PERCENTAGE%"

# Get the current slot name from APIM named value
echo "Reading current slot configuration from APIM..."
CURRENT_SLOT=$(az apim nv show -g $APIMRG -n $APIM --named-value-id current-slot-name --query value -o tsv)

if [ -z "$CURRENT_SLOT" ]; then
    echo "ERROR: Could not retrieve current-slot-name from APIM!"
    exit 1
fi

echo "Current active slot: $CURRENT_SLOT"

# Determine traffic weights based on current slot and provided percentage
if [ "$CURRENT_SLOT" = "green-backend" ]; then
    # Current is green, so shift specified percentage to blue (new deployment)
    BLUE_WEIGHT=$TRAFFIC_PERCENTAGE
    GREEN_WEIGHT=$REMAINDER_PERCENTAGE
    echo "Current slot is green-backend, shifting $TRAFFIC_PERCENTAGE% traffic to blue-backend"
else
    # Current is blue, so shift specified percentage to green (new deployment)
    BLUE_WEIGHT=$REMAINDER_PERCENTAGE
    GREEN_WEIGHT=$TRAFFIC_PERCENTAGE
    echo "Current slot is blue-backend, shifting $TRAFFIC_PERCENTAGE% traffic to green-backend"
fi

echo "Setting backend pool weights - Blue: $BLUE_WEIGHT%, Green: $GREEN_WEIGHT%"

# Update the backend pool with new weights
echo "Updating backend pool weights..."

az deployment sub create --location westeurope --template-file traffic-shifting.bicep \
    --parameters apimResourceGroupName=$APIMRG \
    --parameters apimServiceName=$APIM \
    --parameters blueWeight=$BLUE_WEIGHT \
    --parameters greenWeight=$GREEN_WEIGHT