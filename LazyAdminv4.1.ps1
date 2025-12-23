Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Linq

# --- CONFIGURATION ---
$ScriptPath = $PSScriptRoot
$JsonPath = "$ScriptPath\apps.json"
$ADServer = "xxxx.com" # Banka domain adını buraya girersin

# --- MAIN FORM SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "LazyAdmin v4.1 (Smart Edition)"
$form.Size = New-Object System.Drawing.Size(1000, 750)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = "#f0f0f0"

# --- LOG FUNCTION ---
function Write-Log($message) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logBox.AppendText("[$timestamp] $message `n")
    $logBox.ScrollToCaret()
}

# --- TABS SETUP ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(960, 500)
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$tabControl.SizeMode = "FillToRight"
$form.Controls.Add($tabControl)

$tabDash   = New-Object System.Windows.Forms.TabPage; $tabDash.Text   = "Dashboard"
$tabOffice = New-Object System.Windows.Forms.TabPage; $tabOffice.Text = "Office 365"
$tabSec    = New-Object System.Windows.Forms.TabPage; $tabSec.Text    = "Security"
$tabPrint  = New-Object System.Windows.Forms.TabPage; $tabPrint.Text  = "Printers"
$tabLogs   = New-Object System.Windows.Forms.TabPage; $tabLogs.Text   = "Deep Logs"
$tabRemote = New-Object System.Windows.Forms.TabPage; $tabRemote.Text = "Remote"
$tabMaint  = New-Object System.Windows.Forms.TabPage; $tabMaint.Text  = "Maint."
$tabNet    = New-Object System.Windows.Forms.TabPage; $tabNet.Text    = "Network"
$tabShop   = New-Object System.Windows.Forms.TabPage; $tabShop.Text   = "App Shop"

$tabControl.Controls.Add($tabDash)
$tabControl.Controls.Add($tabOffice)
$tabControl.Controls.Add($tabSec)
$tabControl.Controls.Add($tabPrint)
$tabControl.Controls.Add($tabLogs)
$tabControl.Controls.Add($tabRemote)
$tabControl.Controls.Add($tabMaint)
$tabControl.Controls.Add($tabNet)
$tabControl.Controls.Add($tabShop)

# ==============================================================================
# TAB 1: DASHBOARD
# ==============================================================================
$grpInfo = New-Object System.Windows.Forms.GroupBox; $grpInfo.Text = "System Overview"; $grpInfo.Location = New-Object System.Drawing.Point(10, 10); $grpInfo.Size = New-Object System.Drawing.Size(930, 440); $tabDash.Controls.Add($grpInfo)
$lblInfo = New-Object System.Windows.Forms.Label; $lblInfo.Location = New-Object System.Drawing.Point(20, 30); $lblInfo.Size = New-Object System.Drawing.Size(890, 400); $lblInfo.Font = New-Object System.Drawing.Font("Consolas", 10); $grpInfo.Controls.Add($lblInfo)

function Refresh-Dashboard {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $disk = Get-Volume -DriveLetter C
        $freeSpace = [math]::Round($disk.SizeRemaining / 1GB, 1)
        $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $uptime = (Get-Date) - $os.LastBootUpTime
        $infoText = "Computer Name : $($env:COMPUTERNAME) `nUser          : $($env:USERNAME) `nOS Version    : $($os.Caption) `nFree Disk (C:): $freeSpace GB `nTotal RAM     : $totalRam GB `nSystem Uptime : $([math]::Round($uptime.TotalHours, 1)) Hours `n`n--- Disk Health ---`n"
        $phyDisks = Get-CimInstance -Namespace root\Microsoft\Windows\Storage -ClassName MSFT_PhysicalDisk
        foreach ($d in $phyDisks) { $infoText += "Disk: $($d.FriendlyName) | Status: $($d.HealthStatus) `n" }
        $lblInfo.Text = $infoText
    } catch { $lblInfo.Text = "Error fetching info." }
}
Refresh-Dashboard

# ==============================================================================
# TAB 2: OFFICE & 365 DOCTOR (UPDATED with CHECKS) ✅
# ==============================================================================
# Outlook Repair
$btnOutReset = New-Object System.Windows.Forms.Button; $btnOutReset.Text = "Reset Outlook Profile (Reg)"; $btnOutReset.Location = New-Object System.Drawing.Point(20, 30); $btnOutReset.Size = New-Object System.Drawing.Size(250, 40); $btnOutReset.BackColor="#ffcccc"; $tabOffice.Controls.Add($btnOutReset)
$btnOutReset.Add_Click({
    # VALIDATION: Check if Registry Key Exists
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\Outlook"
    if (-not (Test-Path $regPath)) {
        Write-Log "FAIL: No Outlook profile found in Registry. Office may not be installed."
        [System.Windows.Forms.MessageBox]::Show("Outlook Profile Registry key not found.", "Error", 0, 16)
        return
    }

    $result = [System.Windows.Forms.MessageBox]::Show("This will DELETE the current Outlook profile configuration from Registry. User will need to setup email again.`nAre you sure?", "Warning", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($result -eq 'Yes') {
        Write-Log "Stopping Outlook..."
        Stop-Process -Name "OUTLOOK" -Force -ErrorAction SilentlyContinue
        Write-Log "Removing Registry Keys..."
        Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "SUCCESS: Profile reset. Please restart Outlook."
    }
})

# Office Quick Repair
$btnOffRep = New-Object System.Windows.Forms.Button; $btnOffRep.Text = "Run Office Quick Repair"; $btnOffRep.Location = New-Object System.Drawing.Point(20, 80); $btnOffRep.Size = New-Object System.Drawing.Size(250, 40); $btnOffRep.BackColor="White"; $tabOffice.Controls.Add($btnOffRep)
$btnOffRep.Add_Click({
    Write-Log "Checking for Office installation..."
    # VALIDATION: Check file existence
    $officeClickToRun = "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"
    
    if (Test-Path $officeClickToRun) {
        Write-Log "Office 365 detected. Launching Repair..."
        Start-Process $officeClickToRun -ArgumentList "scenario=Repair", "platform=x64", "culture=en-us", "RepairType=QuickRepair", "DisplayLevel=True"
        Write-Log "Repair wizard launched."
    } else { 
        Write-Log "FAIL: Office C2R Client not found. Is Office installed?" 
        [System.Windows.Forms.MessageBox]::Show("Office Click-To-Run Client not found!", "Error", 0, 16)
    }
})

# Teams Clear
$btnTeamsReset = New-Object System.Windows.Forms.Button; $btnTeamsReset.Text = "Nuke Teams Cache"; $btnTeamsReset.Location = New-Object System.Drawing.Point(300, 30); $btnTeamsReset.Size = New-Object System.Drawing.Size(250, 40); $btnTeamsReset.BackColor="White"; $tabOffice.Controls.Add($btnTeamsReset)
$btnTeamsReset.Add_Click({
    $path = "$env:USERPROFILE\appdata\roaming\Microsoft\Teams"
    
    # VALIDATION
    if (-not (Test-Path $path)) {
        Write-Log "FAIL: Teams Classic folder not found. Nothing to clear."
        return
    }

    Write-Log "Stopping Teams..."
    Stop-Process -Name "ms-teams" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "Teams" -Force -ErrorAction SilentlyContinue
    
    Write-Log "Clearing Cache..."
    try {
        Remove-Item "$path\*" -Recurse -Force -ErrorAction Stop
        Write-Log "SUCCESS: Teams Cache cleared."
    } catch {
        Write-Log "ERROR: Could not clear all files. Teams might still be running."
    }
})

# ==============================================================================
# TAB 3: SECURITY & AUDIT
# ==============================================================================
$txtSec = New-Object System.Windows.Forms.RichTextBox; $txtSec.Location = New-Object System.Drawing.Point(20, 80); $txtSec.Size = New-Object System.Drawing.Size(900, 350); $txtSec.Font = New-Object System.Drawing.Font("Consolas", 9); $tabSec.Controls.Add($txtSec)

$btnBit = New-Object System.Windows.Forms.Button; $btnBit.Text = "Check BitLocker"; $btnBit.Location = New-Object System.Drawing.Point(20, 20); $btnBit.Size = New-Object System.Drawing.Size(200, 40); $btnBit.BackColor="White"; $tabSec.Controls.Add($btnBit)
$btnBit.Add_Click({
    try {
        $status = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop | Select-Object MountPoint, ProtectionStatus, EncryptionPercentage, VolumeStatus
        $txtSec.Text = ($status | Out-String)
    } catch { $txtSec.Text = "Error: BitLocker not available or Access Denied (Run as Admin)." }
})

$btnAdm = New-Object System.Windows.Forms.Button; $btnAdm.Text = "List Local Admins"; $btnAdm.Location = New-Object System.Drawing.Point(230, 20); $btnAdm.Size = New-Object System.Drawing.Size(200, 40); $btnAdm.BackColor="White"; $tabSec.Controls.Add($btnAdm)
$btnAdm.Add_Click({
    try {
        $members = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        $txtSec.Text = "--- LOCAL ADMINISTRATORS ---`n" + ($members | Out-String)
    } catch { $txtSec.Text = "Error: Access Denied (Run as Admin)." }
})

# ==============================================================================
# TAB 4: PRINTERS & PERIPHERALS
# ==============================================================================
$lstPrint = New-Object System.Windows.Forms.ListBox; $lstPrint.Location = New-Object System.Drawing.Point(20, 80); $lstPrint.Size = New-Object System.Drawing.Size(400, 350); $tabPrint.Controls.Add($lstPrint)

$btnScanPrint = New-Object System.Windows.Forms.Button; $btnScanPrint.Text = "Scan Printers"; $btnScanPrint.Location = New-Object System.Drawing.Point(20, 20); $btnScanPrint.Size = New-Object System.Drawing.Size(150, 40); $btnScanPrint.BackColor="White"; $tabPrint.Controls.Add($btnScanPrint)
$btnScanPrint.Add_Click({
    $lstPrint.Items.Clear()
    Get-Printer | ForEach-Object { $lstPrint.Items.Add($_.Name) }
})

$btnResetSpool = New-Object System.Windows.Forms.Button; $btnResetSpool.Text = "Restart Spooler (Fix)"; $btnResetSpool.Location = New-Object System.Drawing.Point(180, 20); $btnResetSpool.Size = New-Object System.Drawing.Size(200, 40); $btnResetSpool.BackColor="#ffebcd"; $tabPrint.Controls.Add($btnResetSpool)
$btnResetSpool.Add_Click({
    Write-Log "Restarting Print Spooler..."
    try {
        Restart-Service Spooler -Force -ErrorAction Stop
        Write-Log "SUCCESS: Spooler restarted."
    } catch { Write-Log "FAIL: Access Denied (Run as Admin)." }
})

$btnTestPage = New-Object System.Windows.Forms.Button; $btnTestPage.Text = "Print Test Page"; $btnTestPage.Location = New-Object System.Drawing.Point(440, 80); $btnTestPage.Size = New-Object System.Drawing.Size(200, 40); $btnTestPage.BackColor="White"; $tabPrint.Controls.Add($btnTestPage)
$btnTestPage.Add_Click({
    $sel = $lstPrint.SelectedItem
    if ($sel) {
        Write-Log "Sending test page to: $sel"
        try { (Get-WmiObject Win32_Printer -Filter "Name='$sel'").PrintTestPage() | Out-Null; Write-Log "Sent." } catch { Write-Log "Error sending test page." }
    } else { Write-Log "Please select a printer from the list first." }
})

# ==============================================================================
# TAB 5: DEEP LOGS
# ==============================================================================
$txtLogs = New-Object System.Windows.Forms.RichTextBox; $txtLogs.Location = New-Object System.Drawing.Point(20, 80); $txtLogs.Size = New-Object System.Drawing.Size(900, 350); $txtLogs.Font = New-Object System.Drawing.Font("Consolas", 9); $txtLogs.BackColor="Black"; $txtLogs.ForeColor="#00ff00"; $tabLogs.Controls.Add($txtLogs)

$btnBsod = New-Object System.Windows.Forms.Button; $btnBsod.Text = "Check Last BSOD"; $btnBsod.Location = New-Object System.Drawing.Point(20, 20); $btnBsod.Size = New-Object System.Drawing.Size(200, 40); $btnBsod.BackColor="White"; $tabLogs.Controls.Add($btnBsod)
$btnBsod.Add_Click({
    $txtLogs.Text = "Scanning System Log for Critical Errors (Last 10)...`n"
    try {
        $errs = Get-EventLog -LogName System -EntryType Error,Warning -Newest 10 -ErrorAction Stop | Where-Object { $_.EventID -eq 41 -or $_.EventID -eq 1001 -or $_.EventID -eq 6008 }
        if ($errs) { $txtLogs.Text += ($errs | Out-String) } else { $txtLogs.Text += "No critical shutdowns found in last 10 events." }
    } catch { $txtLogs.Text += "Access Denied (Run as Admin)." }
})

$btnAppCrash = New-Object System.Windows.Forms.Button; $btnAppCrash.Text = "App Crashes (24h)"; $btnAppCrash.Location = New-Object System.Drawing.Point(230, 20); $btnAppCrash.Size = New-Object System.Drawing.Size(200, 40); $btnAppCrash.BackColor="White"; $tabLogs.Controls.Add($btnAppCrash)
$btnAppCrash.Add_Click({
    $txtLogs.Text = "Scanning Application Log for Crashes (Last 24h)...`n"
    $date = (Get-Date).AddDays(-1)
    try {
        $crashes = Get-EventLog -LogName Application -EntryType Error -After $date -ErrorAction Stop | Where-Object { $_.EventID -eq 1000 }
        if ($crashes) { $txtLogs.Text += ($crashes | Select-Object TimeGenerated, Source, Message | Out-String) } else { $txtLogs.Text += "No app crashes found in 24h." }
    } catch { $txtLogs.Text += "Access Denied (Run as Admin)." }
})

# ==============================================================================
# TAB 6: REMOTE TOOLS
# ==============================================================================
$lblTarget = New-Object System.Windows.Forms.Label; $lblTarget.Text = "Target IP / Hostname:"; $lblTarget.Location = New-Object System.Drawing.Point(20, 30); $lblTarget.AutoSize=$true; $tabRemote.Controls.Add($lblTarget)
$txtTarget = New-Object System.Windows.Forms.TextBox; $txtTarget.Location = New-Object System.Drawing.Point(150, 27); $txtTarget.Size = New-Object System.Drawing.Size(200, 20); $tabRemote.Controls.Add($txtTarget)

$btnRDP = New-Object System.Windows.Forms.Button; $btnRDP.Text = "Launch RDP"; $btnRDP.Location = New-Object System.Drawing.Point(20, 70); $btnRDP.Size = New-Object System.Drawing.Size(150, 40); $btnRDP.BackColor="White"; $tabRemote.Controls.Add($btnRDP)
$btnRDP.Add_Click({
    $t = $txtTarget.Text.Trim()
    if ($t) { Start-Process "mstsc.exe" -ArgumentList "/v:$t" }
})

$btnCShare = New-Object System.Windows.Forms.Button; $btnCShare.Text = "Open C$ Share"; $btnCShare.Location = New-Object System.Drawing.Point(180, 70); $btnCShare.Size = New-Object System.Drawing.Size(150, 40); $btnCShare.BackColor="White"; $tabRemote.Controls.Add($btnCShare)
$btnCShare.Add_Click({
    $t = $txtTarget.Text.Trim()
    if ($t) { Invoke-Item "\\$t\c$" }
})

$btnPingRem = New-Object System.Windows.Forms.Button; $btnPingRem.Text = "Ping Target"; $btnPingRem.Location = New-Object System.Drawing.Point(340, 70); $btnPingRem.Size = New-Object System.Drawing.Size(150, 40); $btnPingRem.BackColor="White"; $tabRemote.Controls.Add($btnPingRem)
$btnPingRem.Add_Click({
    $t = $txtTarget.Text.Trim()
    if ($t) { 
        Write-Log "Pinging $t..."
        try { Test-Connection $t -Count 1 -ErrorAction Stop; Write-Log "Host is UP." } catch { Write-Log "Host is DOWN." }
    }
})

# ==============================================================================
# TAB 7: MAINTENANCE
# ==============================================================================
$btnTemp = New-Object System.Windows.Forms.Button; $btnTemp.Text = "Clean Temp Files"; $btnTemp.Location = New-Object System.Drawing.Point(20, 30); $btnTemp.Size = New-Object System.Drawing.Size(200, 40); $btnTemp.BackColor="White"; $tabMaint.Controls.Add($btnTemp)
$btnTemp.Add_Click({ Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Temp cleaned." })

$btnRecycle = New-Object System.Windows.Forms.Button; $btnRecycle.Text = "Empty Recycle Bin"; $btnRecycle.Location = New-Object System.Drawing.Point(20, 80); $btnRecycle.Size = New-Object System.Drawing.Size(200, 40); $btnRecycle.BackColor="White"; $tabMaint.Controls.Add($btnRecycle)
$btnRecycle.Add_Click({ Clear-RecycleBin -Force -ErrorAction SilentlyContinue; Write-Log "Bin empty." })

$btnSFC = New-Object System.Windows.Forms.Button; $btnSFC.Text = "Run SFC Scannow"; $btnSFC.Location = New-Object System.Drawing.Point(240, 30); $btnSFC.Size = New-Object System.Drawing.Size(200, 40); $btnSFC.BackColor="#fff3cd"; $tabMaint.Controls.Add($btnSFC)
$btnSFC.Add_Click({ Start-Process powershell -ArgumentList "-NoExit", "-Command", "sfc /scannow" -Verb RunAs })

# ==============================================================================
# TAB 8: NETWORK
# ==============================================================================
$btnPingG = New-Object System.Windows.Forms.Button; $btnPingG.Text = "Test Google"; $btnPingG.Location = New-Object System.Drawing.Point(20, 30); $btnPingG.Size = New-Object System.Drawing.Size(200, 40); $btnPingG.BackColor="White"; $tabNet.Controls.Add($btnPingG)
$btnPingG.Add_Click({ try { $p=Test-Connection google.com -Count 1 -ErrorAction Stop; Write-Log "Ping: $($p.ResponseTime)ms" } catch { Write-Log "Fail." } })

$btnWifi = New-Object System.Windows.Forms.Button; $btnWifi.Text = "Show Wi-Fi Passwords"; $btnWifi.Location = New-Object System.Drawing.Point(20, 80); $btnWifi.Size = New-Object System.Drawing.Size(200, 40); $btnWifi.BackColor="White"; $tabNet.Controls.Add($btnWifi)
$btnWifi.Add_Click({
    Write-Log "--- WI-FI ---"
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    foreach ($profile in $profiles) {
        $passOutput = netsh wlan show profile name="$profile" key=clear; $passLine = $passOutput | Select-String "Key Content"
        if ($passLine) { $pass = $passLine.ToString().Split(":")[1].Trim(); Write-Log "$profile : $pass" }
    }
})

$btnFlush = New-Object System.Windows.Forms.Button; $btnFlush.Text = "Flush DNS & IP Renew"; $btnFlush.Location = New-Object System.Drawing.Point(240, 30); $btnFlush.Size = New-Object System.Drawing.Size(200, 40); $btnFlush.BackColor="White"; $tabNet.Controls.Add($btnFlush)
$btnFlush.Add_Click({ Start-Process cmd -ArgumentList "/c ipconfig /flushdns & ipconfig /release & ipconfig /renew" -Verb RunAs -WindowStyle Hidden; Write-Log "Network refreshed." })

# ==============================================================================
# TAB 9: SOFTWARE SHOP (JSON)
# ==============================================================================
if (-not (Test-Path $JsonPath)) {
    $lblErr = New-Object System.Windows.Forms.Label; $lblErr.Text = "apps.json not found!"; $lblErr.ForeColor="Red"; $lblErr.Location = New-Object System.Drawing.Point(20,20); $lblErr.AutoSize=$true; $tabShop.Controls.Add($lblErr)
} else {
    try {
        $RawJson = Get-Content $JsonPath -Raw -Encoding UTF8
        $AppsList = $RawJson | ConvertFrom-Json
        $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $flowPanel.Dock = "Top"; $flowPanel.Height = 350; $flowPanel.AutoScroll = $true; $flowPanel.FlowDirection = "LeftToRight"; $flowPanel.WrapContents = $true; $tabShop.Controls.Add($flowPanel)

        $Categories = $AppsList | Select-Object -ExpandProperty Category -Unique
        foreach ($cat in $Categories) {
            $grp = New-Object System.Windows.Forms.GroupBox; $grp.Text = $cat; $grp.Size = New-Object System.Drawing.Size(220, 200); $grp.Margin = New-Object System.Windows.Forms.Padding(10); $grp.BackColor = "White"
            $myApps = $AppsList | Where-Object { $_.Category -eq $cat }
            $yPos = 20
            foreach ($app in $myApps) {
                $chk = New-Object System.Windows.Forms.CheckBox; $chk.Text = $app.Name; $chk.Tag = $app.Id; $chk.Location = New-Object System.Drawing.Point(10, $yPos); $chk.AutoSize = $true; $grp.Controls.Add($chk); $yPos += 25
            }
            $flowPanel.Controls.Add($grp)
        }
        $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "INSTALL SELECTED APPS"; $btnInstall.Size = New-Object System.Drawing.Size(900, 40); $btnInstall.Location = New-Object System.Drawing.Point(20, 360); $btnInstall.BackColor = "#007acc"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"
        $btnInstall.Add_Click({
            $appsToInstall = @(); foreach ($group in $flowPanel.Controls) { foreach ($ctrl in $group.Controls) { if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Checked) { $appsToInstall += $ctrl.Tag } } }
            if ($appsToInstall.Count -eq 0) { Write-Log "No apps selected."; return }
            foreach ($appID in $appsToInstall) { Write-Log "Installing $appID..."; Start-Process winget -ArgumentList "install -e --id $appID --accept-package-agreements" -Wait; Write-Log "$appID Done." }
        })
        $tabShop.Controls.Add($btnInstall)
    } catch { }
}

# ==============================================================================
# LOG BOX
# ==============================================================================
$logBox = New-Object System.Windows.Forms.RichTextBox; $logBox.Location = New-Object System.Drawing.Point(10, 520); $logBox.Size = New-Object System.Drawing.Size(960, 180); $logBox.ReadOnly = $true; $logBox.BackColor = "Black"; $logBox.ForeColor = "#00FF00"; $logBox.Font = New-Object System.Drawing.Font("Consolas", 10); $form.Controls.Add($logBox)

# --- START ---
Write-Log "LazyAdmin v4.1 SMART Edition Initialized..."
$form.ShowDialog()