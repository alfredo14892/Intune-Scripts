<#
Version: 1.0
Author: Jannik Reinhard (jannikreinhard.com)
Script: Deploy-DefaultFilter
Description:
Default set on intune filteer
Release notes:
Version 1.0: Init
#> 

function Get-GraphAuthentication{
    try {
        Import-Module Microsoft.Graph.DeviceManagement
      } catch {
        Install-Module Microsoft.Graph -Scope CurrentUser
        Import-Module Microsoft.Graph.DeviceManagement
      }


    try {
      Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All"
    } catch {
      Write-Error "Failed to connect to MgGraph"
    }
    
    Select-MgProfile -Name "beta"
}
function Add-IntuneFilter{
    param (
        [parameter(Mandatory=$true)]$Name,
        [parameter(Mandatory=$true)]$Platform,
        [parameter(Mandatory=$true)]$Rule
    )

    Get-MgDeviceManagementAssignmentFilter -Search $Name | ForEach-Object {
            Remove-MgDeviceManagementAssignmentFilter -DeviceAndAppManagementAssignmentFilterId $_.Id
    }
    $params = @{
        DisplayName = $filterPreFix + $Name
        Description = ""
        Platform = $Platform
        Rule = $Rule
        RoleScopeTags = @()
    }
    
    New-MgDeviceManagementAssignmentFilter -BodyParameter $params
}

#########################################################################################################
############################################ Start ######################################################
#########################################################################################################
$global:filterPreFix = "MDM"
Get-GraphAuthentication


###### Windows 10 ######
# Ownership
Add-IntuneFilter -Name "AllPersonalDevices" -Platform "Windows10AndLater" -Rule '(device.deviceOwnership -eq "Personal")'
Add-IntuneFilter -Name "AllCorporateDevices" -Platform "Windows10AndLater" -Rule '(device.deviceOwnership -eq "Corporate")'

# Enrollment Profile
Get-MgDeviceManagementWindowAutopilotDeploymentProfile | ForEach-Object {
    Add-IntuneFilter -Name ("Enrollment"+($($_.DisplayName).Trim())) -Platform "Windows10AndLater" -Rule ('(device.enrollmentProfileName -eq "'+$($_.DisplayName)+'")' )
}

# Operating System SKU
$sku = @("Education", "Enterprise", "IoTEnterprise", "Professional", "Holographic")  
$sku | ForEach-Object {
    Add-IntuneFilter -Name "AllSku$_" -Platform "Windows10AndLater" -Rule ('(device.operatingSystemSKU  -eq "'+$_+'")')
}

# Operating System Version
Add-IntuneFilter -Name "AllWindows11" -Platform "Windows10AndLater" -Rule '(device.osVersion -startsWith "10.0.22")'
Add-IntuneFilter -Name "AllWindows10" -Platform "Windows10AndLater" -Rule '(device.osVersion -startsWith "10.0.1")'
Add-IntuneFilter -Name "AllWindows8.1" -Platform "Windows10AndLater" -Rule '(device.osVersion -startsWith "6.3")'

# Device Category
Get-MgDeviceManagementDeviceCategory | ForEach-Object {
    Add-IntuneFilter -Name ("Category"+($($_.DisplayName).Trim())) -Platform "Windows10AndLater" -Rule ('(device.deviceCategory  -eq "'+$($_.DisplayName)+'")' )
}