Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- MAIN FORM SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "LazyAdmin v1.1 (Ultimate Edition)"
# Pencereyi 650x600'den -> 750x650'ye çıkardık (Ferahlık için)
$form.Size = New-Object System.Drawing.Size(750, 650)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = "#f0f0f0"

# --- LOGGING FUNCTION ---
function Write-Log($message) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logBox.AppendText("[$timestamp] $message `n")
    $logBox.ScrollToCaret()
}

# --- TABS SETUP ---
$tabControl = New-Object System.Windows.Forms.TabControl
# Tab alanını genişlettik
$tabControl.Size = New-Object System.Drawing.Size(710, 380)
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
$grpInfo.Size = New-Object System.Drawing.Size(680, 320) # Genişledi
$tabDash.Controls.Add($grpInfo)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(20, 30)
$lblInfo.Size = New-Object System.Drawing.Size(640, 280)
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
    } catch { $lblInfo.Text = "Error fetching system info." }
}
Refresh-Dashboard

# ==============================================================================
# TAB 2: MAINTENANCE
# ==============================================================================
$btnTemp = New-Object System.Windows.Forms.Button
$btnTemp.Text = "Clean Temp Files"
$btnTemp.Location = New-Object System.Drawing.Point(20, 30)
$btnTemp.Size = New-Object System.Drawing.Size(280, 45) # Genişledi
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
$btnEmptyRecycle.Location = New-Object System.Drawing.Point(20, 90)
$btnEmptyRecycle.Size = New-Object System.Drawing.Size(280, 45) # Genişledi
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
$btnPing.Size = New-Object System.Drawing.Size(280, 40)
$btnPing.BackColor = "White"
$btnPing.Add_Click({
    Write-Log "Pinging google.com..."
    try {
        $ping = Test-Connection google.com -Count 1 -ErrorAction Stop
        Write-Log "Success! Response time: $($ping.ResponseTime)ms"
    } catch { Write-Log "Ping Failed! Check internet." }
})
$tabNet.Controls.Add($btnPing)

$btnWifi = New-Object System.Windows.Forms.Button
$btnWifi.Text = "Show Saved Wi-Fi Passwords"
$btnWifi.Location = New-Object System.Drawing.Point(20, 80)
$btnWifi.Size = New-Object System.Drawing.Size(280, 40)
$btnWifi.BackColor = "#fff3cd"
$btnWifi.Add_Click({
    Write-Log "--- RETRIEVING WI-FI KEYS ---"
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    foreach ($profile in $profiles) {
        $passOutput = netsh wlan show profile name="$profile" key=clear
        $passLine = $passOutput | Select-String "Key Content"
        if ($passLine) {
            $pass = $passLine.ToString().Split(":")[1].Trim()
            Write-Log "SSID: [$profile]  PASS: [$pass]"
        } else {
            Write-Log "SSID: [$profile]  (No Password/Enterprise)"
        }
    }
    Write-Log "-----------------------------"
})
$tabNet.Controls.Add($btnWifi)

$btnFlush = New-Object System.Windows.Forms.Button
$btnFlush.Text = "Fix Network (Flush DNS & Renew)"
$btnFlush.Location = New-Object System.Drawing.Point(20, 130)
$btnFlush.Size = New-Object System.Drawing.Size(280, 40)
$btnFlush.BackColor = "White"
$btnFlush.Add_Click({
    Write-Log "Flushing DNS & Renewing IP..."
    Start-Process cmd -ArgumentList "/c ipconfig /flushdns & ipconfig /release & ipconfig /renew" -Verb RunAs -WindowStyle Hidden
    Write-Log "Commands sent to background."
})
$tabNet.Controls.Add($btnFlush)

$lblIP = New-Object System.Windows.Forms.Label
$lblIP.Text = "Detecting IP..."
$lblIP.Location = New-Object System.Drawing.Point(20, 190)
$lblIP.AutoSize = $true
$lblIP.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$tabNet.Controls.Add($lblIP)

try {
    $ip = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.InterfaceAlias -notlike '*Loopback*'}).IPAddress[0]
    $lblIP.Text = "Local IP: $ip"
} catch { $lblIP.Text = "IP Not Found" }

# ==============================================================================
# TAB 4: TOOLS (RESIZED & FIXED OVERFLOW)
# ==============================================================================

# --- LEFT: QUICK FIXES ---
$grpFix = New-Object System.Windows.Forms.GroupBox
$grpFix.Text = "Quick Fixes"
$grpFix.Location = New-Object System.Drawing.Point(10, 10)
$grpFix.Size = New-Object System.Drawing.Size(320, 330) # Genişledi (320px)
$tabTools.Controls.Add($grpFix)

function New-FixBtn ($txt, $y, $action) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $txt
    $btn.Location = New-Object System.Drawing.Point(20, $y)
    $btn.Size = New-Object System.Drawing.Size(280, 35) # Butonlar genişledi
    $btn.BackColor = "White"
    $btn.Add_Click($action)
    $grpFix.Controls.Add($btn)
}

New-FixBtn "Restart Print Spooler" 30 {
    Write-Log "Restarting Print Spooler..."
    try { Restart-Service Spooler -ErrorAction Stop; Write-Log "Spooler restarted." } catch { Write-Log "Failed. Run as Admin!" }
}

New-FixBtn "Fix Audio (Restart Service)" 75 {
    Write-Log "Restarting Audio Service..."
    try { Restart-Service Audiosrv -Force -ErrorAction Stop; Write-Log "Audio restarted." } catch { Write-Log "Failed. Run as Admin!" }
}

New-FixBtn "Fix Icons (Rebuild Cache)" 120 {
    Write-Log "Rebuilding Icon Cache..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
    Start-Process explorer
    Write-Log "Explorer restarted."
}

New-FixBtn "Generate Battery Report" 165 {
    Write-Log "Generating Battery Report..."
    $reportPath = "$env:USERPROFILE\Desktop\battery-report.html"
    powercfg /batteryreport /output $reportPath | Out-Null
    Write-Log "Saved to Desktop."
    Start-Process $reportPath
}

New-FixBtn "Run System File Checker (SFC)" 210 {
    Write-Log "Launching SFC..."
    Start-Process cmd -ArgumentList "/k sfc /scannow" -Verb RunAs
}

# --- RIGHT: MEGA WINGET SHOP (Wider & Spaced Out) ---
$grpSoft = New-Object System.Windows.Forms.GroupBox
$grpSoft.Text = "Software Shop (Winget)"
$grpSoft.Location = New-Object System.Drawing.Point(340, 10) # Sağa kaydı
$grpSoft.Size = New-Object System.Drawing.Size(350, 330) # Genişledi (350px)
$tabTools.Controls.Add($grpSoft)

# Helper function for checkboxes
function New-AppChk ($txt, $id, $x, $y) {
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = $txt
    $chk.Tag = $id
    $chk.Location = New-Object System.Drawing.Point($x, $y)
    $chk.AutoSize = $true
    $grpSoft.Controls.Add($chk)
    return $chk
}

# Categories
# Sol Sütun (X=20)
$lblBrowsers = New-Object System.Windows.Forms.Label; $lblBrowsers.Text = "Browsers"; $lblBrowsers.ForeColor = "Gray"; $lblBrowsers.Location = New-Object System.Drawing.Point(20, 30); $grpSoft.Controls.Add($lblBrowsers)
$chkChrome  = New-AppChk "Chrome" "Google.Chrome" 20 55
$chkFirefox = New-AppChk "Firefox" "Mozilla.Firefox" 20 80
$chkEdge    = New-AppChk "Edge" "Microsoft.Edge" 20 105

$lblDev = New-Object System.Windows.Forms.Label; $lblDev.Text = "Dev & Tools"; $lblDev.ForeColor = "Gray"; $lblDev.Location = New-Object System.Drawing.Point(20, 145); $grpSoft.Controls.Add($lblDev)
$chkCode    = New-AppChk "VS Code" "Microsoft.VisualStudioCode" 20 170
$chkNotepad = New-AppChk "Notepad++" "Notepad++.Notepad++" 20 195
$chkGit     = New-AppChk "Git" "Git.Git" 20 220

# Sağ Sütun (X=180 -> Genişletildi ki çakışmasın)
$lblMedia = New-Object System.Windows.Forms.Label; $lblMedia.Text = "Media & Utils"; $lblMedia.ForeColor = "Gray"; $lblMedia.Location = New-Object System.Drawing.Point(180, 30); $grpSoft.Controls.Add($lblMedia)
$chkVLC     = New-AppChk "VLC Player" "VideoLAN.VLC" 180 55
$chk7Zip    = New-AppChk "7-Zip" "7zip.7zip" 180 80
$chkZoom    = New-AppChk "Zoom" "Zoom.Zoom" 180 105
$chkAdobe   = New-AppChk "Adobe Reader" "Adobe.Acrobat.Reader.64-bit" 180 130

# Install Button
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Install Selected Apps"
$btnInstall.Location = New-Object System.Drawing.Point(20, 270)
$btnInstall.Size = New-Object System.Drawing.Size(310, 40) # Genişledi
$btnInstall.BackColor = "#007acc"
$btnInstall.ForeColor = "White"
$btnInstall.FlatStyle = "Flat"
$btnInstall.Add_Click({
    $appsToInstall = @()
    foreach ($ctrl in $grpSoft.Controls) {
        if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Checked) { $appsToInstall += $ctrl.Tag }
    }
    
    if ($appsToInstall.Count -eq 0) { Write-Log "No apps selected."; return }

    foreach ($appID in $appsToInstall) {
        Write-Log "Installing $appID..."
        Start-Process winget -ArgumentList "install -e --id $appID --accept-package-agreements --accept-source-agreements" -Wait
    }
    Write-Log "All installations finished."
})
$grpSoft.Controls.Add($btnInstall)

# ==============================================================================
# LOG BOX (BOTTOM)
# ==============================================================================
$logBox = New-Object System.Windows.Forms.RichTextBox
# Log kutusunu aşağı ve genişe aldık
$logBox.Location = New-Object System.Drawing.Point(10, 400)
$logBox.Size = New-Object System.Drawing.Size(710, 200)
$logBox.ReadOnly = $true
$logBox.BackColor = "Black"
$logBox.ForeColor = "#00FF00"
$logBox.Font = New-Object System.Drawing.Font("Consolas", 11)
$form.Controls.Add($logBox)

# --- START ---
Write-Log "LazyAdmin v1.1 initialized..."
$form.ShowDialog()
