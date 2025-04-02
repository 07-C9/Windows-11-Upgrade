# Windows 11 Upgrade as SYSTEM

This repository demonstrates a workflow to in-place upgrade a computer running Windows 10 to Windows 11, while executing as SYSTEM. Used with PDQ Connect but potentially applicable to other management / RMM tools.

## Description

- **spacecheck.ps1**: Checks for 35GB of available space.
- **File Transfer**: Copy the Windows 11 ISO to a Temp folder.
- **W11_upgrade.ps1**: Runs the update as SYSTEM.

### Usage

**spacecheck.ps1**

1. Identifies the boot (primary) drive.  
2. Calculates Free, Used, and Total space in GB.  
3. Outputs this information to a table with `Write-Output`:

```
2024-11-26 19:38:18.075 === Drive Space Information ===

Name  FreeSpaceGB  UsedSpaceGB  TotalSpaceGB
----  ------------ ------------ -------------
C     124.02       113.93       237.96
```

4. Defines an adjustable minimum space requirement (we use 35GB).  
5. Throws an error if the minimum space requirement isn't met.

---

**File Transfer**

Use PDQ Connect's **File Copy Step** to download the Windows 11 ISO (`Windows.iso`) to `C:\Temp`.

---

**W11_upgrade.ps1**

1. Defines path to where the ISO was copied.  
2. Verifies the ISO was successfully copied.  
3. Mounts the ISO and retrieves a drive letter.  
4. Defines a path to `setup.exe` with the ISO mounted.  
5. Verifies the path exists.  
6. Defines parameters for `setup.exe` (customizable; we have it set to not automatically reboot).  
7. Starts the W11 upgrade process:

```
2024-11-26 20:31:02.277 2024-11-26 19:40:44 – ISO file verified at path: C:\Temp\Windows.iso  
2024-11-26 19:40:44 – Mounting the ISO: C:\Temp\Windows.iso  
2024-11-26 19:41:01 – ISO mounted to drive letter: D:  
2024-11-26 19:41:01 – setup.exe found at path: D:\setup.exe  
2024-11-26 19:41:01 – Starting the Windows upgrade process...  
2024-11-26 19:41:01 – Windows upgrade process initiated successfully with PID: 7600
```

8. Monitors the W11 upgrade process every 60 seconds, specifically watching for the following processes to finish: `setup`, `SetupHost`, and `SetupPrep`.

```
2024-11-26 20:27:02 – SetupHost is still running.  
2024-11-26 20:27:02 – SetupPrep is still running.  
2024-11-26 20:28:02 – setup is still running.  
2024-11-26 20:28:02 – SetupHost is still running.  
2024-11-26 20:28:02 – SetupPrep is still running.  
2024-11-26 20:29:02 – setup is still running.  
2024-11-26 20:29:02 – SetupHost is still running.  
2024-11-26 20:29:02 – SetupPrep is still running.  
2024-11-26 20:30:02 – All monitored processes have exited.  
2024-11-26 20:30:02 – Waiting an additional minute before cleanup...  
2024-11-26 20:31:02 – Starting cleanup process...
```

9. Unmounts the ISO and deletes the ISO file.  
10. Initiates a delayed reboot (5-minute countdown) with a full-screen message:

> The Windows 11 installation process is now complete.  
> This system will reboot in five minutes to finish the upgrade.  
> Please save your work.

11. Confirmation script completed successfully with date/time.

```
2024-11-26 20:31:02 – ISO unmounted successfully.  
2024-11-26 20:31:02 – ISO file deleted successfully.  
2024-11-26 20:31:02 – Preparing to reboot the system to complete the upgrade...  
2024-11-26 20:31:02 – Initiating system reboot...  
2024-11-26 20:31:02 – Reboot initiated successfully.  
2024-11-26 20:31:02 – Script execution completed. The system will reboot shortly to complete the upgrade.
```