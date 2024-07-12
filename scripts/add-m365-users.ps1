<#
.SYNOPSIS
This script connects to Microsoft Graph, creates users based on a CSV file, assigns licenses, and exports the result to a CSV file.

.DESCRIPTION
The script reads credentials from a JSON file (credentials.json), connects to Microsoft Graph using the ClientSecretCredential,
creates users and assigns licenses based on a CSV file. It then exports the user list with details to a CSV file. If the credentials file 
does not exist or if there is a failure in connecting to Microsoft Graph, appropriate error messages are displayed.

Before running this script, you need to register an application in Entra ID and create the tenantId, clientId, and clientSecret. You must also add the Directory.ReadWrite.All and User.ReadWrite.All API permissions.

.PARAMETER InputFile
Specifies the path to the input CSV file containing user details and licenses information.

.PARAMETER OutputFile
Specifies the path to the output CSV file. If not provided, the script generates a default file name with the format
UserCreationDetails_YYYYMMDD_HHMMSS.csv.

.EXAMPLE
.\get-m365-users.ps1 -InputFile "C:\path\to\UserRegistration.csv" -OutputFile "C:\path\to\outputfile.csv"
This example runs the script, connects to Microsoft Graph, creates users, assigns licenses, and exports the details to the specified output file.

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

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Set the path to the credentials file
$credentialsPath = Join-Path -Path $scriptDir -ChildPath "credentials.json"

# Check if the credentials file exists
if (-Not (Test-Path -Path $credentialsPath)) {
    Write-Error "The credentials file ($credentialsPath) does not exist. Please create the file and try again."
    exit 1
}

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

# Function to generate random password
function Generate-RandomPassword {
    $Chars = '23456789' + 'abcdefghijkmnpqrstuvwxyz' + 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    return -join ((1..12 | % {Get-Random -input $Chars.ToCharArray()}))
}

# Read user information from CSV file
$users = Import-Csv -Path $InputFile -Encoding UTF8
$outputData = @()

Write-Host "Registering users"
foreach ($user in $users) {
    $UserPrincipalName = $user.UserPrincipalName
    $DisplayName = $user.DisplayName
    if (-not $user.MailNickname) {
        $mailNickname = ($UserPrincipalName -split '@')[0]
    } else {
        $mailNickname = $user.MailNickname
    }

    $userParams = @{
        AccountEnabled = $true
        UserPrincipalName = $UserPrincipalName
        DisplayName = $DisplayName
        mailNickname = $mailNickname
        UsageLocation = "JP"
        PasswordPolicies = "DisablePasswordExpiration,DisableStrongPassword"
    }

    if ($user.MailNickname) { $userParams.MailNickname = $user.MailNickname }
    if ($user.SurName) { $userParams.SurName = $user.SurName }
    if ($user.GivenName) { $userParams.GivenName = $user.GivenName }
    if ($user.JobTitle) { $userParams.JobTitle = $user.JobTitle }
    if ($user.EmployeeId) { $userParams.EmployeeId = $user.EmployeeId }
    if ($user.EmployeeType) { $userParams.EmployeeType = $user.EmployeeType }
    if ($user.Department) { $userParams.Department = $user.Department }
    if ($user.City) { $userParams.City = $user.City }
    if ($user.State) { $userParams.State = $user.State }
    if ($user.Country) { $userParams.Country = $user.Country }
    if ($user.PostalCode) { $userParams.PostalCode = $user.PostalCode }
    if ($user.StreetAddress) { $userParams.StreetAddress = $user.StreetAddress }

    if (-not [string]::IsNullOrEmpty($user.Password)) {
        $Password = $user.Password
    } else {
        $Password = Generate-RandomPassword
    }
    $userParams.PasswordProfile = @{ "Password" = $Password; "forceChangePasswordNextSignIn" = $false }

    New-MgUser @userParams | Select-Object UserPrincipalName > $null
    Write-Host "User created: $UserPrincipalName"

    $outputData += [pscustomobject]@{
        UserPrincipalName = $UserPrincipalName
        DisplayName = $DisplayName
        GivenName = $user.GivenName
        Surname = $user.SurName
        JobTitle = $user.JobTitle
        EmployeeId = $user.EmployeeId
        EmployeeType = $user.EmployeeType
        Department = $user.Department
        City = $user.City
        State = $user.State
        Country = $user.Country
        StreetAddress = $user.StreetAddress
        PostalCode = $user.PostalCode
        Password = $Password
    }
}

Write-Host "Assigning licenses to users"
Import-Csv -Path $InputFile -Encoding UTF8 | `
foreach {
    $UserId = $_.UserPrincipalName
    $Licenses = @()

    if (-not [string]::IsNullOrEmpty($_.SkuId1)) {
        $License1 = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphAssignedLicense -Property @{SkuId = $_.SkuId1}
        $Licenses += $License1
    }

    if (-not [string]::IsNullOrEmpty($_.SkuId2)) {
        $License2 = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphAssignedLicense -Property @{SkuId = $_.SkuId2}
        $Licenses += $License2
    }

    if (-not [string]::IsNullOrEmpty($_.SkuId3)) {
        $License3 = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphAssignedLicense -Property @{SkuId = $_.SkuId3}
        $Licenses += $License3
    }

    if ($Licenses.Count -gt 0) {
        Set-MgUserLicense -UserId $UserId -AddLicenses $Licenses -RemoveLicenses @() | Select-Object UserPrincipalName > $null
        Write-Host "Licenses assined to user: $UserId"
    }
}

# Export the result to a CSV file with UTF8 BOM encoding
try {
    $dateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    if (-Not $OutputFile) {
        $OutputFile = ".\UserCreationDetails_$dateTime.csv"
    }
    $tempFilePath = ".\temp_$dateTime.csv"
    $outputData | Export-Csv -Path $tempFilePath -NoTypeInformation -Encoding UTF8

    # Convert UTF8 to UTF8 BOM
    Get-Content -Path $tempFilePath -Encoding UTF8 | Out-File -Path $OutputFile -Encoding utf8BOM -Force
    Remove-Item -Path $tempFilePath

    Write-Host " "
    Write-Host "User creation details exported to $OutputFile with UTF8 BOM encoding"
} catch {
    Write-Error "Failed to export the user creation details to the CSV file."
} finally {
    # Disconnect from Microsoft Graph
    Disconnect-Graph > $null
    Write-Host "Completed"
}

