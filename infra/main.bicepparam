using 'main.bicep'

param environmentName = 'useracceptance'
param location = 'westeurope'
param functionAppRuntime = 'custom'
param functionAppRuntimeVersion = '1.0'
param resourceGroupName = 'bluegreen-deployment'
param storageAccountName = 'flexconsumptionstorag'
param apimServiceName = 'solarapimuat'
param apimResourceGroupName = 'api-management-demo'

param greenFxPlanName = 'flexplan-tx-green'
param greenFxAppName = 'fx-tx-green-app'

param blueFxPlanName = 'flexplan-tx-blue'
param blueFxAppName = 'fx-tx-blue-app'
