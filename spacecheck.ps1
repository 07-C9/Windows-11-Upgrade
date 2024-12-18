# ==========================================
# PowerShell Script to Check Free Disk Space
# ==========================================

# === 1. Identify the Primary Boot Drive ===

try {
    # Retrieve the system drive letter from the environment variable (e.g., 'C')
    $SystemDriveLetter = $env:SystemDrive.TrimEnd(':')
    
    # Get the PSDrive object for the system drive
    $SystemDrive = Get-PSDrive -Name $SystemDriveLetter -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve the system drive information: $_"
    Exit 1
}

# === 2. Calculate Free, Used, and Total Space in GB ===

# Ensure $SystemDrive is correctly retrieved
if (-not $SystemDrive) {
    Write-Error "System drive information is unavailable."
    Exit 1
}

$FreeSpaceGB = [math]::Round($SystemDrive.Free / 1GB, 2)
$UsedSpaceGB = [math]::Round($SystemDrive.Used / 1GB, 2)
$TotalSpaceGB = [math]::Round(($SystemDrive.Free + $SystemDrive.Used) / 1GB, 2)

# === 3. Display the Drive Information in a Table ===

$driveInfo = [PSCustomObject]@{
    Name        = $SystemDrive.Name
    FreeSpaceGB = $FreeSpaceGB
    UsedSpaceGB = $UsedSpaceGB
    TotalSpaceGB= $TotalSpaceGB
}

Write-Output "=== Drive Space Information ==="
$driveInfo | Format-Table -AutoSize

# === 4. Check Free Space on the Primary Boot Drive ===

# Define the minimum required free space in GB
$minimumFreeSpaceGB = 35

# Check if free space meets the minimum requirement
if ($FreeSpaceGB -lt $minimumFreeSpaceGB) {
    Write-Error "Insufficient free space on drive $($SystemDrive.Name): Required: $minimumFreeSpaceGB GB. Available: $FreeSpaceGB GB."
    
    Write-Output "`n=== Detailed Drive Information ==="
    $driveInfo | Format-Table -AutoSize
    
    Exit 1
}
else {
    Write-Output "Sufficient free space on drive $($SystemDrive.Name): Available: $FreeSpaceGB GB. Proceeding with the upgrade."
}

# === 5. Script Ends Here ===