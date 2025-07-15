targetScope = 'resourceGroup'


@description('API Management service name')
param apimServiceName string

@description('API name')
param apiName string
@description('API display name')
param apiDisplayName string
@description('API path')
param apiPath string

resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimServiceName
}


resource apiResource 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: apimService
  name: apiName
  properties: {
    isCurrent: true
    apiType: 'http'
    description: apiDisplayName
    displayName: apiDisplayName
    format: 'openapi+json'
    value: loadTextContent('open-api-spec.json')
    path: apiPath
    subscriptionRequired: false
  }

  resource policy 'policies@2023-03-01-preview' = {    
    name: 'policy'
    properties: {
      format: 'rawxml'
      value: loadTextContent('./api-policy.xml') 
    }
  }  
}


  