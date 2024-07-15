# M365AdminTools

This project contains tools for managing Microsoft 365 environments using Microsoft Graph API. These tools help administrators automate common tasks such as user management, exporting user details, and cleaning up deleted user objects.

## Features

- **User Management**: Retrieve, create, and delete users within your Microsoft 365 environment.
- **Export to CSV**: Export user details to a CSV file for reporting and analysis.
- **Cleanup Deleted User Objects**: Automatically remove deleted user objects to keep your environment clean and organized.

## Getting Started

### Prerequisites

- PowerShell 7.x
- Microsoft 365 account with appropriate permissions to use Microsoft Graph API

### Installation

1. Change directory to the $HOME

    ```shell
    cd $HOME
    ```

2. Clone the repository:

    ```shell
    git clone https://github.com/yourusername/M365AdminTools.git
    ```

3. Navigate to the project directory:

    ```shell
    cd M365AdminTools
    ```

4. Add $HOME\M365AdminTools\scripts to the $PATH:

    ```shell
    ./setup.ps1
    ```

### Configuration

1. Copy the sample credentials file and rename it:

    ```shell
    cd scripts
    cp credentials.json.sample credentials.json
    ```

2. Edit the `credentials.json` file and enter your Tenant Id, Client Id, and Client Secret:

    ```json
    {
        "tenantId": "your-tenant-id",
        "clientId": "your-client-id",
        "clientSecret": "your-client-secret"
    }
    ```

### Usage


#### Manage License

- To retrieve Microsoft 365 license information

    ```shell
    ./get-m365-license.ps1
    ```

#### User Management

- To retrieve users:

    ```shell
    ./get-m365-users.ps1 [-Outputfile <outputsile>]
    ```

- To create a user:

    ```shell
    ./add-m365-users.ps1 -Inputfile <Inputfile>  [-Outputfile <outputsile>]
    ```

- To delete a user:

    ```shell
    ./remove-m365-users.ps1 -Inputfile <Inputfile>  [-Outputfile <outputsile>]
    ```

- To clean up deleted user objects:

    ```shell
    ./cleanup-m365-deleted-users.ps1
    ```

- To create a Temporary Access Pass:

    ```shell
    ./create-tap.ps1 -Inputfile <Inputfile>  [-Outputfile <outputsile>]
    ```

#### Export User Details

- To export user details to a CSV file:

    ```shell
    ./scripts/export-users.ps1 -OutputFile "users.csv"
    ```

#### Cleanup Deleted User Objects

- To clean up deleted user objects:

    ```shell
    ./scripts/cleanup-deleted-users.ps1
    ```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
