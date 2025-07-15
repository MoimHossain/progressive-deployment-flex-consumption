

targetScope = 'resourceGroup'


@description('API Management service name')
param apimServiceName string

@description('Current slot name key')
param currentSlotNameKey string

@description('Current slot name')
param currentSlotName string


// Reference to existing API Management service
resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimServiceName
}


resource nameValueEntryForSlot 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  name: currentSlotNameKey
  parent: apimService
  properties: {
    displayName: currentSlotNameKey
    secret: false
    value: currentSlotName
  }
}
