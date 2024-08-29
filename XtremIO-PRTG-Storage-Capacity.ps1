<#
.SYNOPSIS
Monitors storage metrics for XtremIO systems and outputs the results to PRTG.

.DESCRIPTION
This script retrieves storage metrics from the XtremIO API for a specific cluster. It then outputs PRTG sensor results with various storage metrics including total physical capacity, logical space in use, free physical space percentage, data reduction ratio, and physical free space. It also sets warning and error thresholds for free physical space.

.PARAMETER XtremIOIP
The IP address or hostname of the XtremIO management system.

.PARAMETER Username
The username for accessing the XtremIO API.

.PARAMETER Password
The password for accessing the XtremIO API.

.INPUTS
None.

.OUTPUTS
Outputs PRTG sensor results with information on various storage metrics for the specified XtremIO system.

.NOTES
Author: Richard Travellin
Date: 8/29/2024
Version: 1.0

.EXAMPLE
./XtremIO-PRTG-Storage-Capacity.ps1 -XtremIOIP "192.168.1.100" -Username "admin" -Password "password"
This example runs the script to check storage metrics for the XtremIO system at the specified IP address using the provided credentials.
#>



# Parameters
param(
    [string]$XtremIOIP,
    [string]$Username,
    [string]$Password
)

# Function to output PRTG error message
function Write-PrtgError {
    param([string]$ErrorMessage)
    Write-Host "<prtg>"
    Write-Host "<error>1</error>"
    Write-Host "<text>$ErrorMessage</text>"
    Write-Host "</prtg>"
}

# Ignore SSL certificate errors (remove this in production)
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Base64 encode credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username, $Password)))

# Set up the request headers
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    Accept = "application/json"
}

# Make the API call to get clusters
$uri = "https://$XtremIOIP/api/json/v3/types/clusters"
try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
}
catch {
    Write-PrtgError "Failed to connect to XtremIO API: $($_.Exception.Message)"
    exit
}

# Extract cluster details
$clusterHref = $response.clusters[0].href
$clusterUri = $clusterHref
try {
    $clusterDetails = Invoke-RestMethod -Uri $clusterUri -Headers $headers -Method Get -ErrorAction Stop
}
catch {
    Write-PrtgError "Failed to retrieve cluster details: $($_.Exception.Message)"
    exit
}

# Function to safely get nested property
function Get-NestedProperty($obj, $propertyPath) {
    $value = $obj
    foreach ($prop in $propertyPath.Split('.')) {
        $value = if ($value -and $value.PSObject.Properties[$prop]) { $value.$prop } else { $null }
        if ($null -eq $value) { return $null }
    }
    return $value
}

# Define metrics
$metrics = @(
    @{Name="Total Physical Capacity (TB)"; Path="content.ud-ssd-space"; CustomUnit="TB"},
    @{Name="Logical Space In Use (TB)"; Path="content.logical-space-in-use"; CustomUnit="TB"},
    @{Name="Free Physical Space (%)"; Path="content.free-ud-ssd-space-in-percent"; CustomUnit="%"},
    @{Name="Data Reduction Ratio"; Path="content.data-reduction-ratio"; CustomUnit=""},
    @{Name="Physical Free Space (TB)"; Path="content.ud-ssd-space"; CustomUnit="TB"}
)

# Start PRTG XML output
Write-Host "<prtg>"

# Output metrics
foreach ($metric in $metrics) {
    $value = Get-NestedProperty $clusterDetails $metric.Path
    if ($null -ne $value) {
        switch ($metric.Name) {
            "Total Physical Capacity (TB)" { 
                $value = [math]::Round($value / 1024 / 1024 / 1024, 2)
            }
            "Logical Space In Use (TB)" { 
                $value = [math]::Round($value / 1024 / 1024 / 1024, 2)
            }
            "Free Physical Space (%)" { 
                $value = [int]$value
                $thresholdValue = 10
                $warningValue = 15
            }
            "Data Reduction Ratio" { 
                $value = [math]::Round($value, 2)
            }
            "Physical Free Space (TB)" { 
                $totalSpace = Get-NestedProperty $clusterDetails "content.ud-ssd-space"
                $freePercentage = Get-NestedProperty $clusterDetails "content.free-ud-ssd-space-in-percent"
                $value = [math]::Round(($totalSpace / 1024 / 1024 / 1024) * ($freePercentage / 100), 2)
            }
        }
        Write-Host "<result>"
        Write-Host "<channel>$($metric.Name)</channel>"
        Write-Host "<value>$value</value>"
        Write-Host "<unit>Custom</unit>"
        Write-Host "<customunit>$($metric.CustomUnit)</customunit>"
		Write-Host "<float>1</float>"
        if ($metric.Name -eq "Free Physical Space (%)") {
            Write-Host "<limitminwarning>$warningValue</limitminwarning>"
            Write-Host "<limitminerror>$thresholdValue</limitminerror>"
            Write-Host "<limitmode>1</limitmode>"
        }
        Write-Host "</result>"
    } else {
        Write-Host "<text>Warning: Null value for $($metric.Name)</text>"
    }
}

# End PRTG XML output
Write-Host "</prtg>"