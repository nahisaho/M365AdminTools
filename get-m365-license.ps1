<#
.SYNOPSIS
This script connects to Microsoft Graph, retrieves Microsoft 365 license information, and displays it.

.DESCRIPTION
The script reads credentials from a JSON file (credentials.json), connects to Microsoft Graph using the ClientSecretCredential,
and retrieves Microsoft 365 license information. It then displays the licenses in a formatted table. If the credentials file 
does not exist or if there is a failure in connecting to Microsoft Graph, appropriate error messages are displayed.

Before running this script, you need to register an application in Entra ID and create the tenantId, clientId, and clientSecret. You must also add the Organization.Read.All API permissions.

.PARAMETER None
This script does not take any parameters.

.EXAMPLE
.\get-ms365-license.ps1
This example runs the script, connects to Microsoft Graph, and displays the Microsoft 365 licenses.

.NOTES
This script requires the Microsoft.Graph module. You can install it using the following command:
Install-Module -Name Microsoft.Graph -Scope CurrentUser

The credentials.json file should be in the same directory as the script and have the following structure:
{
    "tenantId": "your-tenant-id",
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret"
}

.AUTHOR
Hisaho Nakata <nahisaho@microsoft.com>

.VERSION
1.0

.DATE
2024-07-08
#>

# Set the path to the credentials file
$credentialsPath = ".\credentials.json"

# Check if the credentials file exists
if (-Not (Test-Path -Path $credentialsPath)) {
    Write-Error "The credentials file ($credentialsPath) does not exist. Please create the file and try again."
    exit 1
}

# Import the credentials from the JSON file
$credentials = Get-Content -Path $credentialsPath | ConvertFrom-Json

# Extract the tenantId, clientId, and clientSecret
$tenantId = $credentials.tenantId
$clientId = $credentials.clientId
$clientSecret = $credentials.clientSecret

# Convert the client secret to a SecureString
$secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force

# Create a ClientSecretCredential object
$clientSecretCredential = New-Object System.Management.Automation.PSCredential ($clientId, $secureClientSecret)

# Set ErrorActionPreference to stop on errors
$ErrorActionPreference = "Stop"

# Connect to Microsoft Graph
try {
    Connect-MgGraph -NoWelcome -TenantId $tenantId -ClientSecretCredential $clientSecretCredential
} catch {
    Write-Host "Failed to connect to Microsoft Graph: $_"
    exit 1
}

# Retrieve and display the licenses
try {
    Get-MgSubscribedSku | Select-Object -Property Sku*, ConsumedUnits -ExpandProperty PrepaidUnits | ft SkuId, SkuPartNumber -Wrap
} catch {
    Write-Host "Failed to retrieve licenses: $_"
} finally {
    # Disconnect from Microsoft Graph
    Disconnect-Graph > $null
}
