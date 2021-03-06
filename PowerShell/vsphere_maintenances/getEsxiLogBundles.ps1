# Preset command-line arguments
Param(
    [parameter(mandatory=$true)][String]$configFilePath,    # Path of configruration file
    [parameter(mandatory=$true)][String[]]$targetHosts,     # Target ESXi Host(s) to get log-bundle(s)
    [parameter(mandatory=$true)][String]$downloadPath       # Local Path of downloading vm-support
)
# Testing configuration file path
if ((Test-Path -Path $configFilePath) -eq $false) {
    Write-Host "Provided configuration file does not exist, please check the path."
    exit 128
}
$configFile = Convert-Path -Path $configFilePath
Write-Host ">>> Script started, read configuration ..."
Write-Host "Conf File Path :`t $configFile"
Write-Host ""

$lines = Get-Content $configFile
foreach ($line in $lines) {
    if($line -match "^$"){ continue }
    if($line -match "^#"){ continue }
    if($line -match "^\s*;"){ continue }

    $key, $value = $line -split ' = ',2 -replace "`"",''
    Invoke-Expression "`$$key='$value'"
}
Write-Host ">>> Reading parameters :"
Write-Host "vCenter :`t $vCenter"
Write-Host "username :`t $username"
Write-Host "Password File :`t $passwordFilename"
Write-Host ""

# Set input path
$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$passwordFilePath = Join-Path -Path $scriptRoot -ChildPath $passwordFilename
Write-Host ">>> Determine path parameters"
Write-Host "RootPath :`t`t $scriptRoot"
Write-Host "Download Path :`t`t $downloadPath"
Write-Host "PasswordFilePath :`t $passwordFilePath"
Write-Host ""

# Read password from file and make credentials
$password = Get-Content $passwordFilePath | ConvertTo-SecureString
$credential = New-Object -TypeName System.Management.Automation.PsCredential `
    -ArgumentList $username, $password
Write-Host ">>> Reading SecureString done"
Write-Host ""

# Establish connection to vCenter Server
$ErrorActionPreference = "stop"
try {
    Write-Host ">>> Connecting to vCenter Server ..."
    Connect-VIServer -Server $vCenter -Credential $credential
} catch {
    Write-Host "Failed to connect vCenter Server [ $vCenter ] ..."
    Disconnect-VIServer -Server $vCenter -Confirm:$false
    exit 1
}
Write-Host ""


# Collecting vm-support of each ESXi host
$ErrorActionPreference = "continue"
foreach ($h in $targetHosts) {
    try {
        Write-Host ">>> Collecting ESXi log-bundle of [ $h ], it might take some time ..."
        Get-Log -Bundle -VMHost $h -DestinationPath $downloadPath
    } catch {
        Write-Host "Failed to get vm-support of [ $h ]"
    }
}

Write-Host ">>> Script done, disconnecting the server ..."
Disconnect-VIServer -Server $vCenter -Confirm:$false
exit 0
