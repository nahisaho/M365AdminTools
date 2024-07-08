<#
.SYNOPSIS
This script connects to Microsoft Graph, retrieves the ObjectIds of deleted user objects, and removes them.

.DESCRIPTION
The script reads credentials from a JSON file (credentials.json), connects to Microsoft Graph using the ClientSecretCredential,
retrieves the ObjectIds of deleted user objects, and removes them. If the credentials file does not exist or if there is a failure in connecting to Microsoft Graph,
appropriate error messages are displayed.

Before running this script, you need to register an application in Entra ID and create the tenantId, clientId, and clientSecret. You must also add the Directory.ReadWrite.All and User.ReadWrite.All API permissions.

.EXAMPLE
.\remove-deleted-users.ps1
This example runs the script, connects to Microsoft Graph, retrieves the ObjectIds of deleted user objects, and removes them.

.NOTES
This script requires the Microsoft.Graph and Microsoft.Graph.Users modules. You can install them using the following commands:
Install-Module -Name Microsoft.Graph -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Users -Scope CurrentUser

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

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7 -or ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -lt 4)) {
    Write-Host "This script requires PowerShell 7.4 or higher. Your PowerShell version is $($PSVersionTable.PSVersion). Please update to PowerShell 7.4 or higher."
    exit 1
}

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

# Import the Microsoft.Graph.Users module
try {
    Import-Module -Name Microsoft.Graph.Users
} catch {
    Write-Host "Failed to import Microsoft.Graph.Users module: $_"
    exit 1
}

# Retrieve deleted users
$DeletedUsers = Get-MgDirectoryDeletedItem -DirectoryObjectId microsoft.graph.user -Property '*'
$DeletedUsers = $DeletedUsers.AdditionalProperties['value']
foreach ($deletedUser in $DeletedUsers)
{
    $deletedUser  > $null
}

# Remove deleted users
foreach ($deletedUser in $DeletedUsers) {
    $userPrincipalName = $deletedUser.userPrincipalName
    $objectId = $deletedUser.id

    try {
        Remove-MgDirectoryDeletedItem -DirectoryObjectId $objectId -Confirm:$false 2>&1 > $null
        $deletionStatus = "Success"
    } catch {
        $deletionStatus = "Failed: $_"
    }

    Write-Host "UserPrincipalName: $userPrincipalName, ObjectId: $objectId, DeletionStatus: $deletionStatus"
}
