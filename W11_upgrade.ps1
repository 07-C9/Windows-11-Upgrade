# ==========================================
# PowerShell Script to Mount ISO, Upgrade Windows, and Clean Up
# ==========================================

# === Step 1: Define the Path to the ISO in C:\Temp ===
$IsoPath = "C:\Temp\Windows.iso"

# === Step 2: Verify that the ISO File Exists ===
if (-not (Test-Path -Path $IsoPath)) {
    Write-Error "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - ISO file not found at path: $IsoPath"
    exit 1
} else {
    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - ISO file verified at path: $IsoPath"
}

# === Step 3: Mount the ISO and Retrieve Drive Letter ===
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Mounting the ISO: $IsoPath"
try {
    $DiskImg = Mount-DiskImage -ImagePath $IsoPath -PassThru -ErrorAction Stop
    Start-Sleep -Seconds 10  # Brief pause to ensure the ISO is fully mounted
    $VolInfo = $DiskImg | Get-Volume
    if (-not $VolInfo) {
        throw "Failed to retrieve volume information for the mounted ISO."
    }
    $DriveLetter = ($VolInfo.DriveLetter + ":")
    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - ISO mounted to drive letter: $DriveLetter"
} catch {
    Write-Error "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Error mounting ISO: $_"
    exit 1
}

# === Step 4: Path to the Setup Executable ===
$SetupPath = Join-Path -Path $DriveLetter -ChildPath "setup.exe"

# === Step 5: Verify that setup.exe Exists ===
if (-not (Test-Path -Path $SetupPath)) {
    Write-Error "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - setup.exe not found at path: $SetupPath"
    exit 1
} else {
    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - setup.exe found at path: $SetupPath"
}

# === Step 6: Define the Upgrade Arguments ===
$Arguments = '/Auto Upgrade /Quiet /Telemetry Disable /Compat IgnoreWarning /ShowOOBE None /Eula Accept /NoReboot'

# === Step 7: Start the Upgrade Process ===
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Starting the Windows upgrade process..."
try {
    # Start setup.exe directly and capture the process
    $Process = Start-Process -FilePath $SetupPath -ArgumentList $Arguments -WindowStyle Hidden -PassThru -ErrorAction Stop
    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Windows upgrade process initiated successfully with PID: $($Process.Id)"
} catch {
    Write-Error "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Failed to start the upgrade process: $_"
    exit 1
}

# === Step 8: Wait for the Upgrade Process to Complete ===
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Waiting for the upgrade process to complete..."

$CheckInterval = 60  # Check every 60 seconds

try {
    while ($true) {
        # Windows 11 Setup related process names to monitor
        $Processes = @('setup', 'SetupHost', 'SetupPrep')
        $RunningProcesses = $Processes | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue
        } | Where-Object { $_ -and -not $_.HasExited }

        if ($RunningProcesses) {
            foreach ($proc in $RunningProcesses) {
                Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $($proc.Name) is still running."
            }
            Start-Sleep -Seconds $CheckInterval
        } else {
            Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - All monitored processes have exited."
            # Wait an additional minute to ensure everything is done
            Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Waiting an additional minute before cleanup..."
            Start-Sleep -Seconds 60
            break
        }
    }
} catch {
    Write-Error "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Error while waiting for upgrade process: $_"
    exit 1
}

# === Step 9: Perform Cleanup ===
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Starting cleanup process..."

# Unmount the ISO
try {
    Dismount-DiskImage -ImagePath $IsoPath -ErrorAction Stop
    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - ISO unmounted successfully."
} catch {
    Write-Error "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Failed to unmount ISO: $_"
    # Proceeding with deletion attempt
}

# Delete the ISO file
try {
    Remove-Item -Path $IsoPath -Force -ErrorAction Stop
    Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - ISO file deleted successfully."
} catch {
    Write-Error "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Failed to delete ISO file: $_"
}

# === Step 10: Reboot the System ===
Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Preparing to reboot the system to complete the upgrade..."

try {
    # Define the countdown time in seconds (5 minutes)
    $countdown = 300

    # Define the shutdown message for the system notification
    $shutdownMessage = "The Windows 11 installation process is now complete. This system will reboot in five minutes to finish the upgrade. Please save your work."

    # === Step 10a: Initiate System Reboot with Custom Message ===
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Initiating system reboot..."
    try {
        # Initiate a reboot with a 5-minute countdown, force applications to close, and include the custom message
        shutdown.exe /r /t $countdown /c "$shutdownMessage" /f

        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Reboot initiated successfully."
    }
    catch {
        Write-Error "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to initiate system reboot: $_"
        exit 1
    }
}
catch {
    Write-Error "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - An unexpected error occurred: $_"
    exit 1
}

# === Step 11: Script Ends Here ===
Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - Script execution completed. The system will reboot shortly to complete the upgrade."