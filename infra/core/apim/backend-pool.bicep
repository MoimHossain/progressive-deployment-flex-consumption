
targetScope = 'resourceGroup'


@description('API Management service name')
param apimServiceName string

@description('Backend pool name')
param backendPoolName string

@description('Backend pool description')
param backendPoolDescription string = 'Weighted pool of backends'

@description('List of backend resource IDs to include in the pool')
param backendIds array

@description('Corresponding weights for each backend, e.g. [100,0]')
param weights array

// Reference to existing API Management service
resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimServiceName
}

resource backendPool 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  name: backendPoolName
  parent: apimService
  properties: {
    description: backendPoolDescription
    type: 'Pool'
    pool: {
      services: [
        for i in range(0, length(backendIds)): {
          id: backendIds[i]
          priority: 1
          weight: weights[i]
        }
      ]
    }
  }
}
