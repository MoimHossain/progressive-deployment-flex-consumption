targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string
@minLength(1)
param location string 
@minLength(1)
param functionAppRuntime string
@minLength(1)
param functionAppRuntimeVersion string
@minLength(1)
param resourceGroupName string
@minLength(1)
param greenFxPlanName string
@minLength(1)
param greenFxAppName string
@minLength(1)
param storageAccountName string

param apimServiceName string
param apimResourceGroupName string 

@minValue(40)
@maxValue(1000)
param maximumInstanceCount int = 100
param uniqueGuid string = newGuid()
param shortGuid string = substring(uniqueGuid, 0, 3)
var abbrs = loadJsonContent('./abbreviations.json')
// Generate a unique token to be used in naming resources.
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
// Generate a unique function app name if one is not provided.
var greenAppName = !empty(greenFxAppName) ? greenFxAppName : '${shortGuid}${abbrs.webSitesFunctions}${resourceToken}'
// Generate a unique container name that will be used for deployments.
var greenFxDeploymentStorageContainerName = 'app-package-${take(toLower(greenAppName), 32)}-${take(resourceToken, 7)}'

var backendPoolName = 'green-blue-pool'
// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}


resource functionResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  location: location
  tags: tags
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
}

resource apimResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  location: location
  tags: tags
  name: apimResourceGroupName
}

// Backing storage for Azure Functions
module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: functionResourceGroup
  params: {
    location: location
    tags: tags
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    containers: [{name: greenFxDeploymentStorageContainerName}]
  }
}

module monitoring 'core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: functionResourceGroup
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.monitorLogAnalytics}${resourceToken}'
    applicationInsightsName: '${abbrs.monitorApplicationInsights}${resourceToken}'
  }
}

// Azure Functions Flex Consumption
module flexFunction 'core/host/function.bicep' = {
  name: 'functionapp'
  scope: functionResourceGroup
  params: {
    location: location
    tags: tags
    planName: !empty(greenFxPlanName) ? greenFxPlanName : '${abbrs.webServerFarms}${resourceToken}${shortGuid}'
    appName: greenAppName
    storageAccountName: storage.outputs.name
    deploymentStorageContainerName: greenFxDeploymentStorageContainerName
    applicationInsightsName : monitoring.outputs.applicationInsightsName
    functionAppRuntime: functionAppRuntime
    functionAppRuntimeVersion: functionAppRuntimeVersion
    maximumInstanceCount: maximumInstanceCount
  }
}

module apimGreenBackend 'core/apim/backend.bicep' = {
  name: 'green-backend'
  scope: apimResourceGroup
  params: {
    apimServiceName: apimServiceName
    backendName: 'green-backend'
    backendDescription: 'Green Backend service for API Management'
    backendUrl: flexFunction.outputs.functionUri
    backendProtocol: 'http'
    functionKey: flexFunction.outputs.functionKey    
    backendTitle: flexFunction.outputs.functionKey
    validateCertificateChain: true
    validateCertificateName: true
  }
}

module apimBlueBackend 'core/apim/backend.bicep' = {
  name: 'blue-backend'
  scope: apimResourceGroup
  params: {
    apimServiceName: apimServiceName
    backendName: 'blue-backend'
    backendDescription: 'Blue Backend service for API Management'
    backendUrl: flexFunction.outputs.functionUri
    backendProtocol: 'http'
    functionKey: flexFunction.outputs.functionKey    
    backendTitle: flexFunction.outputs.functionKey
    validateCertificateChain: true
    validateCertificateName: true
  }
}

module backendPool 'core/apim/backend-pool.bicep' = {
  name: backendPoolName
  scope: apimResourceGroup
  params: {
    apimServiceName: apimServiceName
    backendPoolName: backendPoolName
    backendIds: [
      apimGreenBackend.outputs.backendId
      apimBlueBackend.outputs.backendId
    ]
    weights: [100, 0]
  }
}

module slotMarker 'core/apim/slot-marker.bicep' = {
  name: 'slot-marker'
  scope: apimResourceGroup
  params: {
    apimServiceName: apimServiceName
    currentSlotNameKey: 'current-slot-name'
    currentSlotName: 'green-backend'
  }
}


module txApi 'core/apim/transaction-api/api.bicep' = {
  name: 'transaction-api'
  scope: apimResourceGroup
  params: {
    apimServiceName: apimServiceName
    apiName: 'transaction-api'
    apiDisplayName: 'Transaction API'
    apiPath: ''
  }
}
