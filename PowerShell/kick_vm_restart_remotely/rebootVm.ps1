# Pre-configurations of PowerCLI
Set-PowerCLIConfiguration -ParticipateInCeip $false -Confirm:$false |Out-Null
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false |Out-Null

# Credentials
$projectRootPath = Split-Path $MyInvocation.MyCommand.Path -Parent
#Write-Host ">>> Project Root Path : $projectRootPath"
$passwordFilePath = Join-Path -Path $projectRootPath -ChildPath "vcenter.secret"
#Write-Host ">>> Password file path : $passwordFilePath "
# Event source name is same as script filename itself
$eventSrcName = $PSCommandPath.Split('\')[-1]

$vCenter = "vcsa01.nfvlab.local"
$username = "administrator@vsphere.local"
$password = Get-Content $passwordFilePath | ConvertTo-SecureString
$credential = New-Object -TypeName System.Management.Automation.PsCredential `
    -ArgumentList $username, $password

# Logging Properties : Create Event source if not exist
if ((Get-ChildItem -Path HKLM:SYSTEM\CurrentControlSet\Services\EventLog\Application | `
    Select-String $eventSrcName) -eq $null) {
    New-EventLog -LogName Application -Source $eventSrcName
    Write-EventLog -LogName Application -Source $eventSrcName -EntryType Information -EventId 1001 `
        -Message "Event Source $eventSrcName not found, created."
}


function writeEvents ([String] $level, [String] $msg) {
    $id = 0
    if ($level -eq "Error") {
        $id = 901
    } elseif ($level -eq "Warning") {
        $id = 801
    } elseif ($level -eq "Information") {
        $id = 1001
    }

    if ($id -ne 0) {
        Write-EventLog -LogName Application -Source $eventSrcName `
            -EntryType $level `
            -EventId $id `
            -Message $msg
    } else {
        Write-Host "EventID not accepted."
    }
}

function getVmPowerState ([String] $vmname) {
    Write-Host "Getting power status of virtual-machine [ $vmname ]"
    writeEvents -level "Information" -msg "Getting power status of virtual-machine [ $vmname ] ..."
    $vmPowerState = (Get-VM -Name $vmname).PowerState
    return $vmPowerState
}

function restartVm ([String] $vmname) {
    Write-Host "Restarting VM [ $vmname ]"
    writeEvents -level "Information" -msg "Restarting virtual-machine [ $vmname ] ..."
    Restart-VM -VM $vmname -Confirm:$false -ErrorAction Continue
    return $?
}



# Check command line arguments
if ($args.Length -eq 0) {
    writeEvents -level "Error" -msg "The script was kicked without any arguments."
    Write-Host "The script was kicked without any arguments."
    exit 255

} elseif ($args.Length -eq 1) {
    Write-Host "The Script accepted proper argument, staring main script..."
    writeEvents -level "Information" -msg "The script accepted proper argument, starting main operations..."

    try {
        Connect-VIServer -Server $vCenter -Credential $credential |Out-Null
        writeEvents -level "Information" -msg "Successfully connected vCenter Server [ $vCenter ]"
    } catch {
#        Disconnect-VIServer -Server $vCenter -Confirm:$false
        Write-Host "Failed to connect vCenter Server ..."
        writeEvents -level "Error" -msg "Failed to connect vCenter Server [ $vCenter ]. Exit the program."
        exit 128
    }

    if ($(restartVm -vmname $args[0]) -eq $false) {
        Write-Host "Tried to restart VM [ $($args[0]) ] , but failed."
        writeEvents -level "Error" -msg "Tried to restart VM, but failed unexpectedly."
        Disconnect-VIServer -Server $vCenter -Confirm:$false
        exit 1
    } else {
        Write-Host "Successfully restart VM [ $($args[0]) ], current VM power state below."
        $powerStatus = getVmPowerState -vmname $args[0]
        Write-Host "PowerState of restarted virtual-machine [ $powerStatus ]"
        Write-Host "The child script worked completely. Exit the program."
        writeEvents -level "Information" -msg "The script worked completely. Exit the program."
        exit 0
    }

} else {
    Write-Host "Too many argument were provied unexpectedly."
    writeEvents -level "Error" -msg "Too many arguments were provoded unexpectedly."
    exit 255

} 
