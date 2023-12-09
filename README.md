# ESXi NIC Information and VMware HCL URL Generator

## Overview
This PowerShell script, `check_nics.ps1`, is designed to gather detailed information about the network interface cards (NICs) on each ESXi host in a vCenter inventory. It retrieves hardware details such as vendor name, device name, vendor ID, device ID, subvendor ID, subdevice ID, driver information, and firmware version. Additionally, the script constructs VMware Hardware Compatibility List (HCL) URLs for each NIC to facilitate compatibility checks.

## Features
- Connects to a vCenter Server and iterates over each ESXi host.
- Retrieves detailed information about each NIC on the ESXi hosts.
- Converts hardware IDs to hexadecimal format for standard compatibility reference.
- Generates a direct VMware HCL URL for each NIC based on its hardware IDs.
- Handles hosts that are not responding or are otherwise inaccessible.
- Outputs the information on the screen and exports it to a JSON file (`esxi_nic_driver_and_firmware_info.json`) for documentation and reporting purposes.

## Usage
1. Update the `config.json` file with your vCenter Server details.
2. Run the script using PowerShell with VMware PowerCLI installed.
3. View the output on the screen and in the generated JSON file.

## Prerequisites
- VMware PowerCLI installed on the system where the script is executed.
- Access to a vCenter Server with ESXi hosts.

## Configuration File
The `config.json` file should contain the following keys:
- `vCenterServer`: The address of the vCenter Server.
- `username`: The username for vCenter Server access.
- `password`: The password for vCenter Server access.

## Author
Daryl Allen

## Note
This script is intended for use in VMware environments for administrative and compatibility checking purposes. Ensure you have the necessary permissions to access and manage your VMware infrastructure.
