<#
.SYNOPSIS
This script connects to Microsoft Graph, retrieves a list of Microsoft 365 users, and exports it to a CSV file.

.DESCRIPTION
The script reads credentials from a JSON file (credentials.json), connects to Microsoft Graph using the ClientSecretCredential,
and retrieves a list of Microsoft 365 users. It then exports the user list to a CSV file. If the credentials file 
does not exist or if there is a failure in connecting to Microsoft Graph, appropriate error messages are displayed.

Before running this script, you need to register an application in Entra ID and create the tenantId, clientId, and clientSecret. You must also add the Directory.ReadWrite.All and User.ReadWrite.All API permissions.

.PARAMETER OutputFile
Specifies the path to the output CSV file. If not provided, the script generates a default file name with the format
RegisteredUsersList_YYYYMMDD_HHMMSS.csv.

.EXAMPLE
.\get-m365-users.ps1 --OutputFile "C:\path\to\outputfile.csv"
This example runs the script, connects to Microsoft Graph, and exports the Microsoft 365 users list to the specified output file.

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
    $OutputFile = "RegisteredUsersList_$timestamp.csv"
}

# Create a temporary file path in the current directory
$tempFileName = [System.IO.Path]::GetRandomFileName() + ".csv"
$tempFilePath = Join-Path -Path (Get-Location) -ChildPath $tempFileName

# Retrieve and export the user list
try {
    $userList = Get-MgUser -All | Select-Object -Property UserPrincipalName, GivenName, Surname, DisplayName, JobTitle, Department, OfficeLocation, BusinessPhones, MobilePhone, FaxNumber, OtherMails, StreetAddress, City, State, PostalCode, Country

    $userListFormatted = $userList | ForEach-Object {
        [PSCustomObject]@{
            "User Name"                = $_.UserPrincipalName
            "First Name"               = $_.GivenName
            "Last Name"                = $_.Surname
            "Display Name"             = $_.DisplayName
            "Job Title"                = $_.JobTitle
            "Department"               = $_.Department
            "Office Number"            = $_.OfficeLocation
            "Office Phone"             = ($_.BusinessPhones -join ", ")
            "Mobile Phone"             = $_.MobilePhone
            "Fax"                      = $_.FaxNumber
            "Alternate email address"  = ($_.OtherMails -join ", ")
            "Address"                  = $_.StreetAddress
            "City"                     = $_.City
            "State or Province"        = $_.State
            "ZIP or Postal Code"       = $_.PostalCode
            "Country or Region"        = $_.Country
        }
    }

    # Add the header to the temporary file
    $header = "User Name,First Name,Last Name,Display Name,Job Title,Department,Office Number,Office Phone,Mobile Phone,Fax,Alternate email address,Address,City,State or Province,ZIP or Postal Code,Country or Region"
    Add-Content -Path $tempFilePath -Value $header

    # Export the user list to the temporary file
    $userListFormatted | Export-Csv -Path $tempFilePath -NoTypeInformation -Append -Encoding UTF8

    # Read the temporary file and write it to the final output file with BOM
    Get-Content -Path $tempFilePath -Encoding UTF8 | Out-File -Path $OutputFile -Encoding UTF8 -Force
    Write-Host "User list exported to $OutputFile"
} catch {
    Write-Host "Failed to retrieve or export user list: $_"
} finally {
    # Disconnect from Microsoft Graph
    Disconnect-Graph > $null

    # Delete the temporary file
    Remove-Item -Path $tempFilePath -Force
}
