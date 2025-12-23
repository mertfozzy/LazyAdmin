Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Linq

# --- CONFIGURATION ---
$ScriptPath = $PSScriptRoot
$JsonPath = "$ScriptPath\apps.json"
$ADServer = "xxxx.com" # Change this to your domain controller if needed

# --- MAIN FORM SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "LazyAdmin v3.0 (Enterprise Edition)"
$form.Size = New-Object System.Drawing.Size(900, 700) # Increased size for Enterprise features
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
$tabControl.Size = New-Object System.Drawing.Size(860, 450)
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($tabControl)

$tabDash  = New-Object System.Windows.Forms.TabPage; $tabDash.Text  = "Dashboard"
$tabAdmin = New-Object System.Windows.Forms.TabPage; $tabAdmin.Text = "Admin Ops" # Restored from SupportButton
$tabMaint = New-Object System.Windows.Forms.TabPage; $tabMaint.Text = "Maintenance"
$tabNet   = New-Object System.Windows.Forms.TabPage; $tabNet.Text   = "Network"
$tabShop  = New-Object System.Windows.Forms.TabPage; $tabShop.Text  = "Software Shop"

$tabControl.Controls.Add($tabDash)
$tabControl.Controls.Add($tabAdmin)
$tabControl.Controls.Add($tabMaint)
$tabControl.Controls.Add($tabNet)
$tabControl.Controls.Add($tabShop)

# ==============================================================================
# TAB 1: DASHBOARD (System Info)
# ==============================================================================
$grpInfo = New-Object System.Windows.Forms.GroupBox
$grpInfo.Text = "System Overview"
$grpInfo.Location = New-Object System.Drawing.Point(10, 10)
$grpInfo.Size = New-Object System.Drawing.Size(830, 390)
$tabDash.Controls.Add($grpInfo)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(20, 30)
$lblInfo.Size = New-Object System.Drawing.Size(790, 340)
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
                    "System Uptime : $([math]::Round($uptime.TotalHours, 1)) Hours `n`n" +
                    "--- Disk Health (SMART) ---`n"
        
        # Adding Disk Health check from SupportButton
        $phyDisks = Get-CimInstance -Namespace root\Microsoft\Windows\Storage -ClassName MSFT_PhysicalDisk
        foreach ($d in $phyDisks) {
            $infoText += "Disk: $($d.FriendlyName) | Status: $($d.HealthStatus) | Temp: $($d.Temperature)C `n"
        }

        $lblInfo.Text = $infoText
    } catch { $lblInfo.Text = "Error fetching system info." }
}
Refresh-Dashboard

# ==============================================================================
# TAB 2: ADMIN OPS (Restored from SupportButton.ps1)
# ==============================================================================

# 1. Java Check
$btnJava = New-Object System.Windows.Forms.Button
$btnJava.Text = "Check Java Version"
$btnJava.Location = New-Object System.Drawing.Point(20, 20)
$btnJava.Size = New-Object System.Drawing.Size(200, 40)
$btnJava.BackColor = "White"
$btnJava.Add_Click({
    $java = Get-Command java -ErrorAction SilentlyContinue
    if ($java) {
        $ver = java -version 2>&1 | Select-Object -First 1
        Write-Log "JAVA FOUND: $ver"
    } else { Write-Log "Java is NOT installed or not in PATH." }
})
$tabAdmin.Controls.Add($btnJava)

# 2. Export Installed Apps
$btnApps = New-Object System.Windows.Forms.Button
$btnApps.Text = "Export Installed Apps (CSV)"
$btnApps.Location = New-Object System.Drawing.Point(20, 70)
$btnApps.Size = New-Object System.Drawing.Size(200, 40)
$btnApps.BackColor = "White"
$btnApps.Add_Click({
    Write-Log "Scanning installed programs..."
    $path = "$env:USERPROFILE\Desktop\Installed_Apps.csv"
    try {
        Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* , HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        Write-Log "List saved to Desktop: Installed_Apps.csv"
    } catch { Write-Log "Error exporting list." }
})
$tabAdmin.Controls.Add($btnApps)

# 3. ACL / User Groups (Requires RSAT)
$grpAD = New-Object System.Windows.Forms.GroupBox; $grpAD.Text = "Active Directory Tools (Requires RSAT)"; $grpAD.Location = New-Object System.Drawing.Point(240, 10); $grpAD.Size = New-Object System.Drawing.Size(350, 180); $tabAdmin.Controls.Add($grpAD)

$lblUser = New-Object System.Windows.Forms.Label; $lblUser.Text = "Username:"; $lblUser.Location = New-Object System.Drawing.Point(15, 30); $lblUser.AutoSize = $true; $grpAD.Controls.Add($lblUser)
$txtUser = New-Object System.Windows.Forms.TextBox; $txtUser.Location = New-Object System.Drawing.Point(80, 25); $txtUser.Size = New-Object System.Drawing.Size(120, 20); $grpAD.Controls.Add($txtUser)
$btnUser = New-Object System.Windows.Forms.Button; $btnUser.Text = "Get User Groups"; $btnUser.Location = New-Object System.Drawing.Point(210, 23); $btnUser.Size = New-Object System.Drawing.Size(120, 25); $btnUser.BackColor="White"; $grpAD.Controls.Add($btnUser)
$btnUser.Add_Click({
    $u = $txtUser.Text.Trim()
    if (-not $u) { Write-Log "Please enter a username."; return }
    Write-Log "Querying groups for: $u"
    try {
        $acls = Get-ADUser -Identity $u -server $ADServer -Properties MemberOf | Select-Object -ExpandProperty MemberOf | ForEach-Object { (Get-ADGroup -server $ADServer $_).Name }
        $acls | ForEach-Object { Write-Log "-> $_" }
    } catch { Write-Log "Error: User not found or AD unreachable." }
})

# 4. Group Members
$lblGrp = New-Object System.Windows.Forms.Label; $lblGrp.Text = "Group:"; $lblGrp.Location = New-Object System.Drawing.Point(15, 70); $lblGrp.AutoSize = $true; $grpAD.Controls.Add($lblGrp)
$txtGrp = New-Object System.Windows.Forms.TextBox; $txtGrp.Location = New-Object System.Drawing.Point(80, 65); $txtGrp.Size = New-Object System.Drawing.Size(120, 20); $grpAD.Controls.Add($txtGrp)
$btnGrp = New-Object System.Windows.Forms.Button; $btnGrp.Text = "Get Members"; $btnGrp.Location = New-Object System.Drawing.Point(210, 63); $btnGrp.Size = New-Object System.Drawing.Size(120, 25); $btnGrp.BackColor="White"; $grpAD.Controls.Add($btnGrp)
$btnGrp.Add_Click({
    $g = $txtGrp.Text.Trim()
    if (-not $g) { Write-Log "Please enter a group name."; return }
    Write-Log "Querying members for: $g"
    try {
        $mems = Get-ADGroupMember -Identity $g -Server $ADServer | Where-Object { $_.objectClass -eq "user" }
        foreach ($m in $mems) { Write-Log "-> $($m.Name) ($($m.SamAccountName))" }
    } catch { Write-Log "Error: Group not found." }
})

# ==============================================================================
# TAB 3: MAINTENANCE (Combined Features)
# ==============================================================================
# Left Side: Generic
$btnTemp = New-Object System.Windows.Forms.Button; $btnTemp.Text = "Clean Temp Files"; $btnTemp.Location = New-Object System.Drawing.Point(20, 30); $btnTemp.Size = New-Object System.Drawing.Size(250, 40); $btnTemp.BackColor="White"; $tabMaint.Controls.Add($btnTemp)
$btnTemp.Add_Click({
    Write-Log "Cleaning Temp..."
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Temp cleaned."
})

$btnRecycle = New-Object System.Windows.Forms.Button; $btnRecycle.Text = "Empty Recycle Bin"; $btnRecycle.Location = New-Object System.Drawing.Point(20, 80); $btnRecycle.Size = New-Object System.Drawing.Size(250, 40); $btnRecycle.BackColor="White"; $tabMaint.Controls.Add($btnRecycle)
$btnRecycle.Add_Click({
    Write-Log "Emptying Recycle Bin..."
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "Bin empty."
})

# Right Side: Corporate (SupportButton Features)
$btnTeams = New-Object System.Windows.Forms.Button; $btnTeams.Text = "Clear Teams/Edge Cache"; $btnTeams.Location = New-Object System.Drawing.Point(300, 30); $btnTeams.Size = New-Object System.Drawing.Size(250, 40); $btnTeams.BackColor="#ffcccc"; $tabMaint.Controls.Add($btnTeams)
$btnTeams.Add_Click({
    Write-Log "Killing Teams & Edge processes..."
    Stop-Process -Name "ms-teams" -ErrorAction SilentlyContinue
    Stop-Process -Name "msedge" -ErrorAction SilentlyContinue
    
    $targetPath = "$env:USERPROFILE\appdata\local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams"
    if (Test-Path $targetPath) {
        Remove-Item -Path "$targetPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Teams cache cleared."
    } else { Write-Log "Teams cache path not found (Classic Teams?)" }
    
    Write-Log "Clearing Internet Cache..."
    Start-Process -FilePath "RunDll32.exe" -ArgumentList "InetCpl.cpl, ClearMyTracksByProcess 8"
    Write-Log "Maintenance complete."
})

$btnSFC = New-Object System.Windows.Forms.Button; $btnSFC.Text = "Run SFC Scannow"; $btnSFC.Location = New-Object System.Drawing.Point(300, 80); $btnSFC.Size = New-Object System.Drawing.Size(250, 40); $btnSFC.BackColor="#fff3cd"; $tabMaint.Controls.Add($btnSFC)
$btnSFC.Add_Click({
    Write-Log "Starting SFC in new window..."
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "sfc /scannow" -Verb RunAs
})


# ==============================================================================
# TAB 4: NETWORK
# ==============================================================================
$btnPing = New-Object System.Windows.Forms.Button; $btnPing.Text = "Test Connectivity (Google)"; $btnPing.Location = New-Object System.Drawing.Point(20, 30); $btnPing.Size = New-Object System.Drawing.Size(250, 40); $btnPing.BackColor="White"; $tabNet.Controls.Add($btnPing)
$btnPing.Add_Click({
    Write-Log "Pinging google.com..."
    try {
        $ping = Test-Connection google.com -Count 1 -ErrorAction Stop
        Write-Log "Success! Time: $($ping.ResponseTime)ms"
    } catch { Write-Log "Ping Failed." }
})

$btnWifi = New-Object System.Windows.Forms.Button; $btnWifi.Text = "Show Saved Wi-Fi Passwords"; $btnWifi.Location = New-Object System.Drawing.Point(20, 80); $btnWifi.Size = New-Object System.Drawing.Size(250, 40); $btnWifi.BackColor="White"; $tabNet.Controls.Add($btnWifi)
$btnWifi.Add_Click({
    Write-Log "--- WI-FI KEYS ---"
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    foreach ($profile in $profiles) {
        $passOutput = netsh wlan show profile name="$profile" key=clear
        $passLine = $passOutput | Select-String "Key Content"
        if ($passLine) {
            $pass = $passLine.ToString().Split(":")[1].Trim()
            Write-Log "SSID: [$profile]  PASS: [$pass]"
        } else { Write-Log "SSID: [$profile]  (No Pass)" }
    }
})

$btnFlush = New-Object System.Windows.Forms.Button; $btnFlush.Text = "Flush DNS & Renew IP"; $btnFlush.Location = New-Object System.Drawing.Point(20, 130); $btnFlush.Size = New-Object System.Drawing.Size(250, 40); $btnFlush.BackColor="White"; $tabNet.Controls.Add($btnFlush)
$btnFlush.Add_Click({
    Write-Log "Executing IPConfig commands..."
    Start-Process cmd -ArgumentList "/c ipconfig /flushdns & ipconfig /release & ipconfig /renew" -Verb RunAs -WindowStyle Hidden
    Write-Log "Network refresh initiated."
})

# ==============================================================================
# TAB 5: SOFTWARE SHOP (DYNAMIC JSON)
# ==============================================================================
# Check if JSON exists
if (-not (Test-Path $JsonPath)) {
    $lblErr = New-Object System.Windows.Forms.Label; $lblErr.Text = "ERROR: apps.json not found!"; $lblErr.ForeColor="Red"; $lblErr.Location = New-Object System.Drawing.Point(20,20); $lblErr.AutoSize=$true; $tabShop.Controls.Add($lblErr)
} else {
    try {
        $RawJson = Get-Content $JsonPath -Raw -Encoding UTF8
        $AppsList = $RawJson | ConvertFrom-Json
        
        $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
        $flowPanel.Dock = "Top"; $flowPanel.Height = 350; $flowPanel.AutoScroll = $true; $flowPanel.FlowDirection = "LeftToRight"; $flowPanel.WrapContents = $true
        $tabShop.Controls.Add($flowPanel)

        $Categories = $AppsList | Select-Object -ExpandProperty Category -Unique
        foreach ($cat in $Categories) {
            $grp = New-Object System.Windows.Forms.GroupBox
            $grp.Text = $cat
            $grp.Size = New-Object System.Drawing.Size(250, 200)
            $grp.Margin = New-Object System.Windows.Forms.Padding(10)
            $grp.BackColor = "White"
            
            $myApps = $AppsList | Where-Object { $_.Category -eq $cat }
            $yPos = 20
            foreach ($app in $myApps) {
                $chk = New-Object System.Windows.Forms.CheckBox
                $chk.Text = $app.Name
                $chk.Tag = $app.Id
                $chk.Location = New-Object System.Drawing.Point(10, $yPos)
                $chk.AutoSize = $true
                $grp.Controls.Add($chk)
                $yPos += 25
            }
            $flowPanel.Controls.Add($grp)
        }

        $btnInstall = New-Object System.Windows.Forms.Button
        $btnInstall.Text = "INSTALL SELECTED APPS (Winget)"
        $btnInstall.Size = New-Object System.Drawing.Size(800, 40)
        $btnInstall.Location = New-Object System.Drawing.Point(20, 360)
        $btnInstall.BackColor = "#007acc"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"
        $btnInstall.Add_Click({
            $appsToInstall = @()
            foreach ($group in $flowPanel.Controls) {
                foreach ($ctrl in $group.Controls) {
                    if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Checked) { $appsToInstall += $ctrl.Tag }
                }
            }
            if ($appsToInstall.Count -eq 0) { Write-Log "No apps selected."; return }
            foreach ($appID in $appsToInstall) {
                Write-Log "Winget Installing: $appID ..."
                Start-Process winget -ArgumentList "install -e --id $appID --accept-package-agreements --accept-source-agreements" -Wait
                Write-Log "$appID Done."
            }
            Write-Log "Batch Installation Complete."
        })
        $tabShop.Controls.Add($btnInstall)

    } catch {
        $lblErr = New-Object System.Windows.Forms.Label; $lblErr.Text = "ERROR reading apps.json!"; $lblErr.ForeColor="Red"; $lblErr.Location = New-Object System.Drawing.Point(20,20); $lblErr.AutoSize=$true; $tabShop.Controls.Add($lblErr)
    }
}

# ==============================================================================
# LOG BOX
# ==============================================================================
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(10, 470)
$logBox.Size = New-Object System.Drawing.Size(860, 180)
$logBox.ReadOnly = $true
$logBox.BackColor = "Black"
$logBox.ForeColor = "#00FF00"
$logBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($logBox)

# --- START ---
Write-Log "LazyAdmin v3.0 Enterprise initialized..."
$form.ShowDialog()