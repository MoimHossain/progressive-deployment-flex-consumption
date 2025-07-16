using 'traffic-shifting.bicep'


param apimResourceGroupName = 'api-management-demo'
param apimServiceName = 'solarapimuat'

param greenWeight = int(readEnvironmentVariable('GREEN_WEIGHT', '0')) 
param blueWeight = int(readEnvironmentVariable('BLUE_WEIGHT', '0')) 
