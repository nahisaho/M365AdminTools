<#
.SYNOPSIS
This script connects to Microsoft Graph, removes users based on a CSV file, and exports the result to a CSV file.

.DESCRIPTION
The script reads credentials from a JSON file (credentials.json), connects to Microsoft Graph using the ClientSecretCredential,
removes users based on a CSV file. It then exports the user deletion results to a CSV file. If the credentials file 
does not exist or if there is a failure in connecting to Microsoft Graph, appropriate error messages are displayed.

Before running this script, you need to register an application in Entra ID and create the tenantId, clientId, and clientSecret. You must also add the Directory.ReadWrite.All and User.ReadWrite.All API permissions.

.PARAMETER InputFile
Specifies the path to the input CSV file containing user details for deletion.

.PARAMETER OutputFile
Specifies the path to the output CSV file. If not provided, the script generates a default file name with the format
RemovedUsers_YYYYMMDD_HHMMSS.csv.

.EXAMPLE
.\remove-m365-users.ps1 -InputFile "C:\path\to\UserDeletion.csv" -OutputFile "C:\path\to\outputfile.csv"
This example runs the script, connects to Microsoft Graph, removes users, and exports the details to the specified output file.

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

param (
    [string]$InputFile,
    [string]$OutputFile
)

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

# Generate default output file name if not provided
if (-Not $OutputFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = "RemovedUsers_$timestamp.csv"
}

# Create a temporary file path in the current directory
$tempFileName = [System.IO.Path]::GetRandomFileName() + ".csv"
$tempFilePath = Join-Path -Path (Get-Location) -ChildPath $tempFileName

# Read user information from CSV file
$userList = Import-Csv -Path $InputFile -Encoding UTF8
$deletionResults = @()

Write-Host "Removing users"
foreach ($user in $userList) {
    try {
        Remove-MgUser -UserId $user.UserPrincipalName 
        $result = [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            Status            = "Successfully removed"
        }
        # Write-Output $result 
        Write-Host "User removed: $($user.UserPrincipalName)"
        $deletionResults += $result
    } catch {
        $error = [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            Status            = "Failed to delete - $_.Exception.Message"
        }
        Write-Error $error
        $deletionResults += $error
    }
}

# Export the result to a CSV file
try {
    $deletionResults | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
    Write-Host " "
    Write-Host "User deletion details exported to $OutputFile"
} catch {
    Write-Error "Failed to export the user deletion details to the CSV file."
} finally {
    # Disconnect from Microsoft Graph
    Disconnect-Graph > $null
    Write-Host "Completed"
}
