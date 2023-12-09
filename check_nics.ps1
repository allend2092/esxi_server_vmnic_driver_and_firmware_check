<#
.SYNOPSIS
This script gathers detailed information about the network interface cards (NICs) on each ESXi host in a vCenter inventory, including hardware details and VMware Hardware Compatibility List (HCL) URLs.

.DESCRIPTION
The script connects to a vCenter Server and iterates over each ESXi host to retrieve information about each NIC, such as the vendor name, device name, vendor ID, device ID, subvendor ID, subdevice ID, driver information, and firmware version. It also constructs a VMware HCL URL for each NIC for compatibility checks. The output is displayed on the screen and exported to a JSON file.

.AUTHOR
Daryl Allen

.NOTES
Version:        1.0
Compatibility:  VMware PowerCLI
#>

# Read the configuration file 'config.json' and convert its content to a PowerShell object
$config = Get-Content -Path 'config.json' | ConvertFrom-Json

# Attempt to establish a connection to the vCenter Server
try {
    Connect-VIServer -Server $config.vCenterServer -User $config.username -Password $config.password -Force
} catch {
    Write-Error "Failed to connect to vCenter Server: $_"
    exit
}

# Initialize an array to hold NIC information objects
$nicInfoList = @()

# Get all ESXi hosts from the vCenter inventory
$esxiHosts = Get-VMHost

foreach ($esxiHost in $esxiHosts) {
    # Check if the host is accessible
    if ($esxiHost.ConnectionState -ne "Connected") {
        Write-Host "Skipping host $($esxiHost.Name) as it is not accessible."
        continue
    }

    Write-Host "Executing commands on host: $($esxiHost.Name)"

    # Get ESXCLI instance for the host
    $esxCli = Get-EsxCli -VMHost $esxiHost -V2

    # Execute 'esxcli network nic list' and store NIC names
    try {
        $nicList = $esxCli.network.nic.list.Invoke()
        $nicNames = $nicList | ForEach-Object { $_.Name }
    } catch {
        Write-Error "Failed to execute 'esxcli network nic list' on $($esxiHost.Name): $_"
        continue
    }

    # Execute 'esxcli hardware pci list' and 'esxcli network nic get' for each NIC
    try {
        $pciDevices = $esxCli.hardware.pci.list.Invoke()
        
        foreach ($nicName in $nicNames) {
            $filteredDevices = $pciDevices | Where-Object { $_.VMkernelName -eq $nicName }
            foreach ($device in $filteredDevices) {
                $hexVID = [convert]::ToString([int]$device.VendorID, 16)
                $hexDID = [convert]::ToString([int]$device.DeviceID, 16)
                $hexSVID = [convert]::ToString([int]$device.SubVendorID, 16)
                $hexSSID = [convert]::ToString([int]$device.SubDeviceID, 16)

                # Construct the VMware HCL URL
                $vmwareHclUrl = "https://www.vmware.com/resources/compatibility/search.php?deviceCategory=io&details=1&releases=578,518&VID=$hexVID&DID=$hexDID&SVID=$hexSVID&SSID=$hexSSID&page=1&display_interval=10&sortColumn=Partner&sortOrder=Asc"

                # Get additional NIC information
                $nicInfo = $esxCli.network.nic.get.Invoke(@{nicname=$nicName})

                # Create an object for each NIC and add it to the list
                $nicObject = [PSCustomObject]@{
                    ESXi_Host = $($esxiHost.Name)
                    NIC = $nicName
                    VendorName = $device.VendorName
                    DeviceName = $device.DeviceName
                    VendorID = $hexVID
                    DeviceID = $hexDID
                    SubVendorID = $hexSVID
                    SubDeviceID = $hexSSID
                    VMwareHCLUrl = $vmwareHclUrl
                    Driver = $nicInfo.Driver
                    DriverVersion = $nicInfo.DriverInfo.Version
                    FirmwareVersion = $nicInfo.DriverInfo.FirmwareVersion
                }
                $nicInfoList += $nicObject

                # Display the information on the screen
                Write-Host ($nicObject | Format-List | Out-String)
            }
        }
    } catch {
        Write-Error "Failed to execute commands on $($esxiHost.Name): $_"
    }
}

# Export the NIC information to a JSON file
$nicInfoList | ConvertTo-Json -Depth 5 | Set-Content -Path "esxi_nic_driver_and_firmware_info.json"

# Disconnect from the vCenter Server
Disconnect-VIServer -Server $config.vCenterServer -Confirm:$false
