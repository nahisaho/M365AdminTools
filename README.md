# M365AdminTools

This project contains tools for managing Microsoft 365 environments using Microsoft Graph API.

## Features

- User management (retrieve, create, delete users)
- Export user details to CSV
- Cleanup deleted user object

## Getting Started

### Prerequisites

- PowerShell 7.x
- Microsoft 365 account with appropriate permissions

### Installation

```shell
git clone https://github.com/yourusername/M365AdminTools.git
cd M365AdminTools
./setup.ps1
```

### Configuration

Copy the sample credentials file and rename it:

```shell
cd scripts
cp credentials.json.sample credentials.json
```

Edit the credentials.json file and enter your Tenant Id, Client Id, and Client Secret:

```
{
    "tenantId": "your-tenant-id",
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret"
}
```

