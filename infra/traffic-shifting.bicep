targetScope = 'subscription'

@description('API Management service name')
param apimServiceName string = 'solarapimuat'
@description('API Management resource group name')
param apimResourceGroupName string = 'api-management-demo'
param blueWeight int 
param greenWeight int

var backendPoolName = 'green-blue-pool'
var greenBackendName = 'green-backend'
var blueBackendName = 'blue-backend'



resource apimResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {  
  name: apimResourceGroupName
}

resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimServiceName
  scope: apimResourceGroup
}

resource apimGreenBackend 'Microsoft.ApiManagement/service/backends@2024-05-01' existing = {
  name: greenBackendName
  parent: apimService
}

resource apimBlueBackend 'Microsoft.ApiManagement/service/backends@2024-05-01' existing = {
  name: blueBackendName
  parent: apimService
}

module backendPool 'core/apim/backend-pool.bicep' = {
  name: backendPoolName
  scope: apimResourceGroup
  params: {
    apimServiceName: apimServiceName
    backendPoolName: backendPoolName
    backendIds: [
      apimGreenBackend.id
      apimBlueBackend.id
    ]
    weights: [greenWeight, blueWeight]
  }
}
