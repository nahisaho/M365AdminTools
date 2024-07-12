param (
    [string]$InputFile,
    [string]$OutputFile
)

function Get-RandomPassword {
    $Length = 12
    $Password = ([char[]](48..57 + 65..90 + 97..122) | Get-Random -Count $Length) -join ''
    return $Password
}

# Import necessary modules
Import-Module Microsoft.Graph
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Set the path to the credentials file
$credentialsPath = Join-Path -Path $scriptDir -ChildPath "credentials.json"
$configtapPath = Join-Path -Path $scriptDir -ChildPath "configTAP.json"

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

# Read input CSV file
try {
    $users = Import-Csv -Path $InputFile
} catch {
    Write-Error "Failed to read the input CSV file."
    exit
}


$outputData = @()

# Set json
$properties = @{}
$properties.isUsableOnce = $temporaryAccessPassAuthenticationMethod.isUsableOnce
$properties.LifetimeInMinutes = $temporaryAccessPassAuthenticationMethod.lifetimeInMinutes
$propertiesJSON = $properties


foreach ($user in $users) {
    try {
        $Password = if ($user.Password -eq $null) { Get-RandomPassword } else { $user.Password }
        # Issue Temporary Access Pass
        $response = New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $User.UserPrincipalName -BodyParameter $propertiesJSON 

        # Extract the Temporary Access Pass details from the response
        $TemporaryAccessPass = $response.TemporaryAccessPass


        $outputData += [pscustomobject]@{
            UserPrincipalName = $User.UserPrincipalName
            DisplayName = $User.DisplayName
            GivenName = $User.GivenName
            Surname = $User.Surname
            TAP = $TemporaryAccessPass
        }
        Write-Host "Created user and issued Temporary Access Pass: $($User.UserPrincipalName)"
    } catch {
        Write-Error "Failed to create user or issue Temporary Access Pass for user: $($user.UserPrincipalName)"
        Write-Error "Error message: $_"
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
