# XtremIO PRTG Sensor Script
![image](https://github.com/user-attachments/assets/18f35ee5-d088-49f4-a3e7-c127bf503b44)


## Description

This PowerShell script is designed to monitor Dell EMC XtremIO storage systems and integrate with PRTG Network Monitor. It retrieves key storage metrics from the XtremIO API and formats them for PRTG, allowing for easy monitoring and alerting of XtremIO storage performance and capacity.

## Features

- Retrieves and reports the following metrics:
  - Total Physical Capacity (TB)
  - Logical Space In Use (TB)
  - Free Physical Space (%)
  - Data Reduction Ratio
  - Physical Free Space (TB)
- Sets configurable warning and error thresholds for Free Physical Space
- Outputs results in PRTG-compatible XML format
- Handles SSL certificate errors for environments with self-signed certificates

## Prerequisites

- PowerShell 5.1 or later
- PRTG Network Monitor
- Access to XtremIO API (IP address/hostname, username, and password)

## Installation

1. Clone this repository or download the `XtremIO-PRTG-Sensor.ps1` file.
2. Place the script in your PRTG Custom Sensors directory, typically:
   `C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML`

## Usage

In PRTG, create a new sensor using the "EXE/Script Advanced" sensor type. Use the following parameters:

- **Sensor Name:** XtremIO Storage Metrics
- **Parent Device:** Your XtremIO device in PRTG
- **Inherit Access Rights:** Yes
- **Scanning Interval:** 5 minutes (or as needed)
- **EXE/Script:** XtremIO-PRTG-Sensor.ps1
- **Parameters:** %host %linuxuser %linuxpassword

Replace `%host`, `%linuxuser`, and `%linuxpassword` with the appropriate placeholders for your PRTG setup.

## Configuration

The script sets warning and error thresholds for Free Physical Space:
- Warning: Below 15%
- Error: Below 10%

To modify these thresholds, edit the following lines in the script:

```powershell
$thresholdValue = 10  # Error threshold
$warningValue = 15    # Warning threshold
```

## Troubleshooting

- Ensure that the XtremIO API is accessible from the PRTG probe server.
- Verify that the provided credentials have sufficient permissions to access the XtremIO API.
- Check PRTG logs for any execution errors.


## License

Distributed under the MIT License. See `LICENSE` file for more information.

## Contact

Your Name - your.email@example.com

Project Link: [https://github.com/yourusername/xtremio-prtg-sensor](https://github.com/yourusername/xtremio-prtg-sensor)

## Acknowledgements

- [Dell EMC XtremIO](https://www.delltechnologies.com/en-us/storage/xtremio-all-flash.htm)
- [PRTG Network Monitor](https://www.paessler.com/prtg)
