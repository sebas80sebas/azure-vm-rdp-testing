# Azure VM RDP Session Testing Guide

## Overview
This guide walks through creating a Windows 10 VM in Azure and testing methods to keep programs running after RDP disconnection, replicating the on-premises behavior where sessions remained open 24/7.

---

## Step 1: Create Windows 10 VM in Azure Portal

### Creating the VM

1. **Access Azure Portal** at portal.azure.com

2. **Create Virtual Machine:**
   - Click "Create a resource" → "Virtual Machine"
   - Or search "Virtual Machines" → "+ Create"

3. **Basic Configuration:**
   - **Subscription:** Select your subscription
   - **Resource Group:** Create new (e.g., "rg-test-rdp")
   - **VM name:** vm-test-rdp-w10
   - **Region:** Choose closest region (e.g., West Europe)
   - **Image:** Windows 10 Pro
   - **Size:** Standard_B2s (2 vCPUs, 4GB RAM - sufficient for testing)
   - **Username:** azureuser (or preferred username)
   - **Password:** Create strong password (save it!)
   - **Public inbound ports:** Allow selected ports
   - **Select inbound ports:** RDP (3389)

4. **Disks Tab:**
   - OS disk type: Standard SSD (cost-effective)

5. **Networking Tab:**
   - Leave default values (auto-creates VNet)
   - **NIC network security group:** Basic
   - Ensure RDP (3389) is allowed

6. **Review + Create:**
   - Review all settings
   - Click "Create"
   - Wait 3-5 minutes for deployment

---

## Step 2: Connect to the VM

### RDP Connection

1. **Get Public IP:**
   - Navigate to your VM in Azure Portal
   - Copy the "Public IP address"

2. **Connect via RDP:**
   - Open "Remote Desktop Connection" (mstsc) on your PC
   - Paste the public IP
   - Username: azureuser (the one you created)
   - Password: your defined password
   - Accept the certificate warning

---

## Step 3: Prepare Test Environment

### Create Test Program

**Inside the VM:**

1. **Create test directory:**
   - Create folder `C:\test\`

2. **Create simple test script:**
   
   Open Notepad and create the following script:
   ```batch
   @echo off
   :loop
   echo %date% %time% - Program running >> C:\test\log.txt
   timeout /t 60
   goto loop
   ```
   
   - Save as `C:\test\test-program.bat`
   - This script writes to a log file every 60 seconds

3. **Alternative - Use Real Application:**
   - Copy your actual application to the VM
   - Note the full path to the .exe file

---

## Step 4: Testing Methods

### Test 1 - Basic RDP Disconnect

**Objective:** Verify if programs continue running when RDP session is disconnected (not logged off).

**Steps:**

1. Run your program manually (double-click `test-program.bat`)
2. Close RDP window (click X, do NOT logoff)
3. Wait 5-10 minutes
4. Reconnect via RDP
5. **Verify:** Is the program still running? Is the log file being updated?

**Expected Result:** Program should continue running 

**Limitation:** Program will stop if VM restarts

---

### Test 2 - NSSM Service (Recommended Method)

**Objective:** Convert the program into a Windows Service for persistent execution.

#### Download and Install NSSM

1. **Download NSSM:**
   - Open browser in the VM
   - Go to https://nssm.cc/download
   - Download and extract ZIP to `C:\nssm\`

2. **Install Program as Service:**
   
   Open Command Prompt as Administrator:
   ```cmd
   C:\nssm\nssm.exe install TestService
   ```

3. **Configure in NSSM Window:**
   - **Path:** `C:\test\test-program.bat`
   - **Startup directory:** `C:\test\`
   - Click "Install service"

4. **Start the Service:**
   ```cmd
   net start TestService
   ```
   
   Or use Services Manager:
   - Open `services.msc`
   - Find "TestService"
   - Right-click → Start

5. **Configure Auto-Start:**
   - In `services.msc`
   - Find your service
   - Right-click → Properties
   - Startup type: **Automatic**

#### Testing the Service

**Test A - RDP Disconnect:**
1. Disconnect RDP completely
2. Wait 10 minutes
3. Reconnect
4. Check log file: `C:\test\log.txt`
5. **Verify:** Service should still be running and writing to log 

**Test B - VM Restart:**
1. From Azure Portal → Select your VM → Click "Restart"
2. Wait for VM to restart (2-3 minutes)
3. Reconnect via RDP
4. Check log file immediately
5. **Verify:** Service should auto-start and continue logging 

---

## Results Documentation

Create a results table:

| Test | Method | RDP Disconnect | VM Restart | Result |
|------|--------|----------------|------------|--------|
| 1 | Manual | Working | Not Working | Lost on restart |
| 2 | NSSM Service | Working | Working | Works perfectly |

---

## Key Benefits of NSSM Service Approach

Program runs independently of RDP sessions  
Survives VM restarts automatically  
No need to keep RDP session open  
Cloud best practice  
More reliable than session-dependent methods  
Works for most standard executables and scripts  

---

## Testing Checklist

```
☐ VM created with Windows 10
☐ Connected via RDP
☐ Test program created at C:\test\
☐ Test 1: RDP disconnect tested
☐ NSSM downloaded and installed
☐ Service created and started
☐ Test 2A: RDP disconnect tested with service
☐ Test 2B: VM restart tested
☐ Logs verified after each test
☐ Results documented
```

---

## Notes

- The NSSM method is **recommended for Azure VMs** as it's more robust than keeping RDP sessions open
- This approach replicates on-premises behavior without requiring 24/7 RDP connections
- Services automatically restart after VM maintenance or updates
- For production environments, always configure service recovery options in `services.msc`
