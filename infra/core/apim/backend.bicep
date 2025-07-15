
targetScope = 'resourceGroup'


@description('API Management service name')
param apimServiceName string

@description('Backend name')
param backendName string

@description('Backend URL')
param backendUrl string

@description('Backend protocol')
@allowed(['http', 'soap'])
param backendProtocol string = 'http'

@description('Backend description')
param backendDescription string = 'Backend service for API Management'

@description('Backend title')
param backendTitle string

@description('Validate SSL certificate chain')
param validateCertificateChain bool = true

@description('Validate SSL certificate name')
param validateCertificateName bool = true

// Reference to existing API Management service
resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = {
  name: apimServiceName
}

// API Management Backend
resource apimBackend 'Microsoft.ApiManagement/service/backends@2024-05-01' = {
  name: backendName
  parent: apimService
  properties: {
    description: backendDescription
    url: backendUrl
    protocol: backendProtocol
    title: backendTitle
    tls: {
      validateCertificateChain: validateCertificateChain
      validateCertificateName: validateCertificateName
    }
  }
}

// Outputs
@description('Backend resource ID')
output backendId string = apimBackend.id

@description('Backend name')
output backendName string = apimBackend.name

@description('Backend URL')
output backendUrl string = apimBackend.properties.url

@description('API Management service name')
output apimServiceName string = apimService.name
