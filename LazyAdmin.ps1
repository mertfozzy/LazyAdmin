Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- MAIN FORM ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "LazyAdmin v1.0 (Classic Edition)"
$form.Size = New-Object System.Drawing.Size(620, 550) # Biraz boyunu uzattık
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

# --- TABS ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(590, 300)
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($tabControl)

$tabDash  = New-Object System.Windows.Forms.TabPage; $tabDash.Text  = "Dashboard"
$tabClean = New-Object System.Windows.Forms.TabPage; $tabClean.Text = "Maintenance"
$tabNet   = New-Object System.Windows.Forms.TabPage; $tabNet.Text   = "Network"
$tabTools = New-Object System.Windows.Forms.TabPage; $tabTools.Text = "Tools"

$tabControl.Controls.Add($tabDash)
$tabControl.Controls.Add($tabClean)
$tabControl.Controls.Add($tabNet)
$tabControl.Controls.Add($tabTools)

# ==============================================================================
# TAB 1: DASHBOARD
# ==============================================================================
$grpInfo = New-Object System.Windows.Forms.GroupBox
$grpInfo.Text = "System Information"
$grpInfo.Location = New-Object System.Drawing.Point(10, 10)
$grpInfo.Size = New-Object System.Drawing.Size(560, 250)
$tabDash.Controls.Add($grpInfo)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(20, 30)
$lblInfo.Size = New-Object System.Drawing.Size(520, 200)
$lblInfo.Font = New-Object System.Drawing.Font("Consolas", 10)
$grpInfo.Controls.Add($lblInfo)

function Refresh-Dashboard {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $disk = Get-Volume -DriveLetter C
        $freeSpace = [math]::Round($disk.SizeRemaining / 1GB, 1)
        $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $uptime = (Get-Date) - $os.LastBootUpTime
        
        $infoText = "Computer Name : $($env:COMPUTERNAME) `n" +
                    "User          : $($env:USERNAME) `n" +
                    "OS Version    : $($os.Caption) `n" +
                    "Free Disk (C:): $freeSpace GB `n" +
                    "Total RAM     : $totalRam GB `n" +
                    "System Uptime : $([math]::Round($uptime.TotalHours, 1)) Hours"
        
        $lblInfo.Text = $infoText
    } catch { $lblInfo.Text = "Error fetching info." }
}
Refresh-Dashboard

# ==============================================================================
# TAB 2: MAINTENANCE
# ==============================================================================
$btnTemp = New-Object System.Windows.Forms.Button
$btnTemp.Text = "Clean Temp Files"
$btnTemp.Location = New-Object System.Drawing.Point(20, 30)
$btnTemp.Size = New-Object System.Drawing.Size(200, 40)
$btnTemp.BackColor = "White"
$btnTemp.Add_Click({
    Write-Log "Cleaning Temp folder..."
    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Temp folder cleaned."
    } catch { Write-Log "Error cleaning temp." }
})
$tabClean.Controls.Add($btnTemp)

$btnEmptyRecycle = New-Object System.Windows.Forms.Button
$btnEmptyRecycle.Text = "Empty Recycle Bin"
$btnEmptyRecycle.Location = New-Object System.Drawing.Point(20, 80)
$btnEmptyRecycle.Size = New-Object System.Drawing.Size(200, 40)
$btnEmptyRecycle.BackColor = "White"
$btnEmptyRecycle.Add_Click({
    Write-Log "Emptying Recycle Bin..."
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log "Recycle Bin is empty."
    } catch { Write-Log "Recycle bin already empty or access denied." }
})
$tabClean.Controls.Add($btnEmptyRecycle)

# ==============================================================================
# TAB 3: NETWORK
# ==============================================================================
$btnPing = New-Object System.Windows.Forms.Button
$btnPing.Text = "Test Google Connectivity"
$btnPing.Location = New-Object System.Drawing.Point(20, 30)
$btnPing.Size = New-Object System.Drawing.Size(200, 40)
$btnPing.BackColor = "White"
$btnPing.Add_Click({
    Write-Log "Pinging google.com..."
    try {
        $ping = Test-Connection google.com -Count 1 -ErrorAction Stop
        Write-Log "Success! Response time: $($ping.ResponseTime)ms"
    } catch { Write-Log "Ping Failed! Check internet." }
})
$tabNet.Controls.Add($btnPing)

$lblIP = New-Object System.Windows.Forms.Label
$lblIP.Text = "Detecting IP..."
$lblIP.Location = New-Object System.Drawing.Point(20, 90)
$lblIP.AutoSize = $true
$lblIP.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$tabNet.Controls.Add($lblIP)

try {
    $ip = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.InterfaceAlias -notlike '*Loopback*'}).IPAddress[0]
    $lblIP.Text = "Local IP: $ip"
} catch { $lblIP.Text = "IP Not Found" }

# ==============================================================================
# TAB 4: TOOLS (NEW!)
# ==============================================================================

# Group 1: Quick Fixes
$grpFix = New-Object System.Windows.Forms.GroupBox
$grpFix.Text = "Quick Fixes"
$grpFix.Location = New-Object System.Drawing.Point(10, 10)
$grpFix.Size = New-Object System.Drawing.Size(270, 250)
$tabTools.Controls.Add($grpFix)

# Button: Spooler Reset
$btnSpooler = New-Object System.Windows.Forms.Button
$btnSpooler.Text = "Restart Print Spooler"
$btnSpooler.Location = New-Object System.Drawing.Point(20, 30)
$btnSpooler.Size = New-Object System.Drawing.Size(230, 40)
$btnSpooler.BackColor = "White"
$btnSpooler.Add_Click({
    Write-Log "Restarting Print Spooler..."
    try {
        Restart-Service Spooler -ErrorAction Stop
        Write-Log "Print Spooler restarted successfully."
    } catch { Write-Log "Failed. Try running as Administrator." }
})
$grpFix.Controls.Add($btnSpooler)

# Button: Battery Report
$btnBattery = New-Object System.Windows.Forms.Button
$btnBattery.Text = "Generate Battery Report"
$btnBattery.Location = New-Object System.Drawing.Point(20, 80)
$btnBattery.Size = New-Object System.Drawing.Size(230, 40)
$btnBattery.BackColor = "White"
$btnBattery.Add_Click({
    Write-Log "Generating Battery Report..."
    try {
        $reportPath = "$env:USERPROFILE\Desktop\battery-report.html"
        powercfg /batteryreport /output $reportPath | Out-Null
        Write-Log "Report saved to Desktop!"
        Start-Process $reportPath
    } catch { Write-Log "Error generating report." }
})
$grpFix.Controls.Add($btnBattery)

# Button: SFC Scannow
$btnSFC = New-Object System.Windows.Forms.Button
$btnSFC.Text = "Run System File Checker (SFC)"
$btnSFC.Location = New-Object System.Drawing.Point(20, 130)
$btnSFC.Size = New-Object System.Drawing.Size(230, 40)
$btnSFC.BackColor = "White"
$btnSFC.Add_Click({
    Write-Log "Launching SFC..."
    Start-Process cmd -ArgumentList "/k sfc /scannow" -Verb RunAs
})
$grpFix.Controls.Add($btnSFC)


# Group 2: Software Installer (Winget)
$grpSoft = New-Object System.Windows.Forms.GroupBox
$grpSoft.Text = "Software Installer (Winget)"
$grpSoft.Location = New-Object System.Drawing.Point(290, 10)
$grpSoft.Size = New-Object System.Drawing.Size(270, 250)
$tabTools.Controls.Add($grpSoft)

# Checkboxes
$chkChrome  = New-Object System.Windows.Forms.CheckBox; $chkChrome.Text = "Google Chrome"; $chkChrome.Location = New-Object System.Drawing.Point(20, 30); $chkChrome.AutoSize = $true
$chkFirefox = New-Object System.Windows.Forms.CheckBox; $chkFirefox.Text = "Mozilla Firefox"; $chkFirefox.Location = New-Object System.Drawing.Point(20, 60); $chkFirefox.AutoSize = $true
$chk7Zip    = New-Object System.Windows.Forms.CheckBox; $chk7Zip.Text = "7-Zip"; $chk7Zip.Location = New-Object System.Drawing.Point(20, 90); $chk7Zip.AutoSize = $true
$chkNotepad = New-Object System.Windows.Forms.CheckBox; $chkNotepad.Text = "Notepad++"; $chkNotepad.Location = New-Object System.Drawing.Point(20, 120); $chkNotepad.AutoSize = $true
$chkVLC     = New-Object System.Windows.Forms.CheckBox; $chkVLC.Text = "VLC Media Player"; $chkVLC.Location = New-Object System.Drawing.Point(20, 150); $chkVLC.AutoSize = $true

$grpSoft.Controls.Add($chkChrome)
$grpSoft.Controls.Add($chkFirefox)
$grpSoft.Controls.Add($chk7Zip)
$grpSoft.Controls.Add($chkNotepad)
$grpSoft.Controls.Add($chkVLC)

# Install Button
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Install Selected"
$btnInstall.Location = New-Object System.Drawing.Point(20, 190)
$btnInstall.Size = New-Object System.Drawing.Size(230, 40)
$btnInstall.BackColor = "#007acc"
$btnInstall.ForeColor = "White"
$btnInstall.FlatStyle = "Flat"
$btnInstall.Add_Click({
    Write-Log "Checking selections..."
    $apps = @()
    if ($chkChrome.Checked)  { $apps += "Google.Chrome" }
    if ($chkFirefox.Checked) { $apps += "Mozilla.Firefox" }
    if ($chk7Zip.Checked)    { $apps += "7zip.7zip" }
    if ($chkNotepad.Checked) { $apps += "Notepad++.Notepad++" }
    if ($chkVLC.Checked)     { $apps += "VideoLAN.VLC" }
    
    if ($apps.Count -eq 0) {
        Write-Log "No apps selected."
        return
    }

    Write-Log "Installing: $($apps -join ', ')"
    foreach ($app in $apps) {
        Write-Log "Winget: Installing $app..."
        # Launch winget in a separate visible window to show progress
        Start-Process winget -ArgumentList "install -e --id $app" -Wait
    }
    Write-Log "Installation process finished."
})
$grpSoft.Controls.Add($btnInstall)

# ==============================================================================
# LOG BOX (BOTTOM)
# ==============================================================================
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(10, 320)
$logBox.Size = New-Object System.Drawing.Size(590, 180)
$logBox.ReadOnly = $true
$logBox.BackColor = "Black"
$logBox.ForeColor = "#00FF00"
$logBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($logBox)

# --- START ---
Write-Log "LazyAdmin v1.0 initialized..."
$form.ShowDialog()