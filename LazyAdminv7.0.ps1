Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Linq
Add-Type -AssemblyName Microsoft.VisualBasic

# --- CONFIGURATION ---
$ScriptPath = $PSScriptRoot
$SettingsPath = "$ScriptPath\settings.json"
$JsonPath = "$ScriptPath\apps.json"

# Varsayılan Ayarlar
$AppName = "LazyAdmin v7.0 (Network Master)"
$MainColor = "#f0f0f0"
$BtnColor = "White"

if (Test-Path $SettingsPath) {
    try {
        $Settings = Get-Content $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $AppName = $Settings.AppName
        $MainColor = $Settings.SecondaryColor 
    } catch { }
}

# --- FORM SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = $AppName
$form.Size = New-Object System.Drawing.Size(1150, 780)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = $MainColor

function Write-Log($message) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logBox.AppendText("[$timestamp] $message `n")
    $logBox.ScrollToCaret()
}

# --- TABS ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(1110, 520)
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$tabControl.SizeMode = "FillToRight"
$form.Controls.Add($tabControl)

$tabDash   = New-Object System.Windows.Forms.TabPage; $tabDash.Text   = "Dashboard"
$tabNet    = New-Object System.Windows.Forms.TabPage; $tabNet.Text    = "Network++"  # GÜNCELLENDİ
$tabShop   = New-Object System.Windows.Forms.TabPage; $tabShop.Text   = "App Shop XL" # GÜNCELLENDİ
$tabUser   = New-Object System.Windows.Forms.TabPage; $tabUser.Text   = "User Mgr"   
$tabOffice = New-Object System.Windows.Forms.TabPage; $tabOffice.Text = "Office 365"
$tabDebloat= New-Object System.Windows.Forms.TabPage; $tabDebloat.Text= "Debloat"    
$tabSec    = New-Object System.Windows.Forms.TabPage; $tabSec.Text    = "Security"
$tabPrint  = New-Object System.Windows.Forms.TabPage; $tabPrint.Text  = "Printers"
$tabWinUpd = New-Object System.Windows.Forms.TabPage; $tabWinUpd.Text = "Win Update"
$tabMaint  = New-Object System.Windows.Forms.TabPage; $tabMaint.Text  = "Maint."

$tabControl.Controls.Add($tabDash)
$tabControl.Controls.Add($tabNet)
$tabControl.Controls.Add($tabShop)
$tabControl.Controls.Add($tabUser)
$tabControl.Controls.Add($tabOffice)
$tabControl.Controls.Add($tabDebloat)
$tabControl.Controls.Add($tabSec)
$tabControl.Controls.Add($tabPrint)
$tabControl.Controls.Add($tabWinUpd)
$tabControl.Controls.Add($tabMaint)

# ==============================================================================
# TAB 1: DASHBOARD (Klasik)
# ==============================================================================
$grpInfo = New-Object System.Windows.Forms.GroupBox; $grpInfo.Text = "System Info"; $grpInfo.Location = New-Object System.Drawing.Point(10, 10); $grpInfo.Size = New-Object System.Drawing.Size(1080, 460); $tabDash.Controls.Add($grpInfo)
$lblInfo = New-Object System.Windows.Forms.Label; $lblInfo.Location = New-Object System.Drawing.Point(20, 30); $lblInfo.Size = New-Object System.Drawing.Size(1040, 420); $lblInfo.Font = New-Object System.Drawing.Font("Consolas", 10); $grpInfo.Controls.Add($lblInfo)

function Refresh-Dashboard {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $bios = Get-CimInstance Win32_BIOS
        $cs = Get-CimInstance Win32_ComputerSystem
        $disk = Get-Volume -DriveLetter C
        $freeSpace = [math]::Round($disk.SizeRemaining / 1GB, 1)
        $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        
        $infoText = "HOSTNAME      : $($env:COMPUTERNAME) `nCURRENT USER  : $($env:USERNAME) `nMODEL         : $($cs.Manufacturer) - $($cs.Model)`nSERIAL (BIOS) : $($bios.SerialNumber) `nOS VERSION    : $($os.Caption) `n`nDISK FREE (C) : $freeSpace GB `nTOTAL RAM     : $totalRam GB `nLAST BOOT     : $($os.LastBootUpTime) `n`n--- IP CONFIGURATION ---`n"
        
        $ips = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.InterfaceAlias -notlike '*Loopback*' }
        foreach ($ip in $ips) { $infoText += "Interface: $($ip.InterfaceAlias) -> IP: $($ip.IPAddress) `n" }
        
        $lblInfo.Text = $infoText
    } catch { $lblInfo.Text = "Error fetching info." }
}
Refresh-Dashboard

# ==============================================================================
# TAB 2: NETWORK MASTER (6+ Functions) 🌐🚀
# ==============================================================================
# 1. Connectivity Check
$grpNetTest = New-Object System.Windows.Forms.GroupBox; $grpNetTest.Text = "Connectivity"; $grpNetTest.Location = New-Object System.Drawing.Point(20, 20); $grpNetTest.Size = New-Object System.Drawing.Size(300, 150); $tabNet.Controls.Add($grpNetTest)

$btnPingG = New-Object System.Windows.Forms.Button; $btnPingG.Text = "Ping Google"; $btnPingG.Location = New-Object System.Drawing.Point(20, 30); $btnPingG.Size = New-Object System.Drawing.Size(120, 40); $btnPingG.BackColor=$BtnColor; $grpNetTest.Controls.Add($btnPingG)
$btnPingG.Add_Click({ try { $p=Test-Connection google.com -Count 1 -ErrorAction Stop; Write-Log "Google Ping: $($p.ResponseTime)ms" } catch { Write-Log "Ping Failed." } })

$btnPubIP = New-Object System.Windows.Forms.Button; $btnPubIP.Text = "Get Public IP"; $btnPubIP.Location = New-Object System.Drawing.Point(150, 30); $btnPubIP.Size = New-Object System.Drawing.Size(120, 40); $btnPubIP.BackColor=$BtnColor; $grpNetTest.Controls.Add($btnPubIP)
$btnPubIP.Add_Click({ try { $ip = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 3; Write-Log "Public IP: $ip" } catch { Write-Log "Could not get Public IP." } })

$btnLat = New-Object System.Windows.Forms.Button; $btnLat.Text = "Latency Check (Multi)"; $btnLat.Location = New-Object System.Drawing.Point(20, 80); $btnLat.Size = New-Object System.Drawing.Size(250, 40); $btnLat.BackColor=$BtnColor; $grpNetTest.Controls.Add($btnLat)
$btnLat.Add_Click({
    Write-Log "Checking latency..."
    $hosts = @("8.8.8.8 (Google)", "1.1.1.1 (Cloudflare)", "208.67.222.222 (OpenDNS)")
    foreach ($h in $hosts) { $ip = $h.Split(" ")[0]; try { $t = Test-Connection $ip -Count 1; Write-Log "$h : $($t.ResponseTime)ms" } catch { Write-Log "$h : Timeout" } }
})

# 2. Repair & Config
$grpNetFix = New-Object System.Windows.Forms.GroupBox; $grpNetFix.Text = "Repair & Config"; $grpNetFix.Location = New-Object System.Drawing.Point(340, 20); $grpNetFix.Size = New-Object System.Drawing.Size(300, 150); $tabNet.Controls.Add($grpNetFix)

$btnFlush = New-Object System.Windows.Forms.Button; $btnFlush.Text = "Flush DNS"; $btnFlush.Location = New-Object System.Drawing.Point(20, 30); $btnFlush.Size = New-Object System.Drawing.Size(120, 40); $btnFlush.BackColor=$BtnColor; $grpNetFix.Controls.Add($btnFlush)
$btnFlush.Add_Click({ Start-Process cmd -ArgumentList "/c ipconfig /flushdns" -Verb RunAs -WindowStyle Hidden; Write-Log "DNS Flushed." })

$btnRenew = New-Object System.Windows.Forms.Button; $btnRenew.Text = "Release/Renew IP"; $btnRenew.Location = New-Object System.Drawing.Point(150, 30); $btnRenew.Size = New-Object System.Drawing.Size(120, 40); $btnRenew.BackColor=$BtnColor; $grpNetFix.Controls.Add($btnRenew)
$btnRenew.Add_Click({ Write-Log "Releasing & Renewing IP..."; Start-Process cmd -ArgumentList "/c ipconfig /release & ipconfig /renew" -Verb RunAs -WindowStyle Hidden; Write-Log "Done." })

$btnResetNet = New-Object System.Windows.Forms.Button; $btnResetNet.Text = "⚠️ Reset TCP/IP Stack"; $btnResetNet.Location = New-Object System.Drawing.Point(20, 80); $btnResetNet.Size = New-Object System.Drawing.Size(250, 40); $btnResetNet.BackColor="#ffcccc"; $grpNetFix.Controls.Add($btnResetNet)
$btnResetNet.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("This will reset Winsock and TCP/IP. Reboot required. Continue?", "Warning", [System.Windows.Forms.MessageBoxButtons]::YesNo) -eq 'Yes') {
        Start-Process cmd -ArgumentList "/c netsh winsock reset & netsh int ip reset" -Verb RunAs
        Write-Log "Network Reset. PLEASE REBOOT."
    }
})

# 3. Discovery (LAN & WiFi)
$grpDisc = New-Object System.Windows.Forms.GroupBox; $grpDisc.Text = "Discovery"; $grpDisc.Location = New-Object System.Drawing.Point(660, 20); $grpDisc.Size = New-Object System.Drawing.Size(300, 150); $tabNet.Controls.Add($grpDisc)

$btnWifi = New-Object System.Windows.Forms.Button; $btnWifi.Text = "Show Wi-Fi Passwords"; $btnWifi.Location = New-Object System.Drawing.Point(20, 30); $btnWifi.Size = New-Object System.Drawing.Size(260, 40); $btnWifi.BackColor=$BtnColor; $grpDisc.Controls.Add($btnWifi)
$btnWifi.Add_Click({
    Write-Log "--- SAVED WI-FI PASSWORDS ---"
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    foreach ($profile in $profiles) {
        $passOutput = netsh wlan show profile name="$profile" key=clear; $passLine = $passOutput | Select-String "Key Content"
        if ($passLine) { $pass = $passLine.ToString().Split(":")[1].Trim(); Write-Log "$profile : $pass" }
    }
})

$btnArp = New-Object System.Windows.Forms.Button; $btnArp.Text = "Scan LAN Devices (ARP)"; $btnArp.Location = New-Object System.Drawing.Point(20, 80); $btnArp.Size = New-Object System.Drawing.Size(260, 40); $btnArp.BackColor=$BtnColor; $grpDisc.Controls.Add($btnArp)
$btnArp.Add_Click({
    Write-Log "Scanning local neighbors (ARP)..."
    $neighbors = Get-NetNeighbor -AddressFamily IPv4 | Where-Object { $_.State -ne "Unreachable" } | Select-Object IPAddress, LinkLayerAddress, State
    if ($neighbors) { $neighbors | ForEach-Object { Write-Log "IP: $($_.IPAddress) - MAC: $($_.LinkLayerAddress)" } } else { Write-Log "No neighbors found." }
})

# Port Tester (Alt Kısım)
$lblPort = New-Object System.Windows.Forms.Label; $lblPort.Text = "Port Tester:"; $lblPort.Location = New-Object System.Drawing.Point(20, 200); $lblPort.AutoSize=$true; $tabNet.Controls.Add($lblPort)
$txtPort = New-Object System.Windows.Forms.TextBox; $txtPort.Location = New-Object System.Drawing.Point(100, 197); $txtPort.Size = New-Object System.Drawing.Size(200, 20); $txtPort.Text="google.com:443"; $tabNet.Controls.Add($txtPort)
$btnPort = New-Object System.Windows.Forms.Button; $btnPort.Text = "Test Port"; $btnPort.Location = New-Object System.Drawing.Point(310, 195); $btnPort.Size = New-Object System.Drawing.Size(100, 25); $btnPort.BackColor=$BtnColor; $tabNet.Controls.Add($btnPort)
$btnPort.Add_Click({
    $pArr = $txtPort.Text.Split(":")
    if ($pArr.Count -eq 2) { try { $t = Test-NetConnection -ComputerName $pArr[0] -Port $pArr[1] -WarningAction SilentlyContinue; if ($t.TcpTestSucceeded) { Write-Log "OPEN: $($txtPort.Text)" } else { Write-Log "CLOSED: $($txtPort.Text)" } } catch { Write-Log "Error." } }
})

# ==============================================================================
# TAB 3: APP SHOP XL (Expanded) 🛒
# ==============================================================================
if (-not (Test-Path $JsonPath)) {
    # Eğer dosya yoksa internetten yedeği çekmeyi dene
    try { $AppsList = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/MertRepo/lazyadmin/main/apps.json" -ErrorAction SilentlyContinue } catch {}
} else {
    $RawJson = Get-Content $JsonPath -Raw -Encoding UTF8; $AppsList = $RawJson | ConvertFrom-Json
}

if ($AppsList) {
    $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $flowPanel.Dock = "Top"; $flowPanel.Height = 400; $flowPanel.AutoScroll = $true; $tabShop.Controls.Add($flowPanel)
    
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "INSTALL SELECTED APPS (WINGET)"; $btnInstall.Location = New-Object System.Drawing.Point(20, 420); $btnInstall.Size = New-Object System.Drawing.Size(900,40); $btnInstall.BackColor="#007acc"; $btnInstall.ForeColor="White"; $tabShop.Controls.Add($btnInstall)
    
    $Categories = $AppsList | Select-Object -ExpandProperty Category -Unique
    foreach ($cat in $Categories) {
        $grp = New-Object System.Windows.Forms.GroupBox; $grp.Text = $cat; $grp.Size = New-Object System.Drawing.Size(220, 250); $grp.BackColor="White"; $grp.Margin = New-Object System.Windows.Forms.Padding(5); $flowPanel.Controls.Add($grp)
        
        $myApps = $AppsList | Where-Object { $_.Category -eq $cat }
        $y = 20
        foreach ($app in $myApps) { 
            $c = New-Object System.Windows.Forms.CheckBox; $c.Text=$app.Name; $c.Tag=$app.Id; $c.Location=New-Object System.Drawing.Point(10,$y); $c.AutoSize=$true
            # Tooltip ekleyelim (Mouse üzerine gelince açıklama çıksın)
            $tt = New-Object System.Windows.Forms.ToolTip; $tt.SetToolTip($c, $app.Description)
            $grp.Controls.Add($c); $y+=25 
        }
    }
    
    $btnInstall.Add_Click({ 
        $appsToInstall = @(); foreach ($group in $flowPanel.Controls) { foreach ($ctrl in $group.Controls) { if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Checked) { $appsToInstall += $ctrl.Tag } } }
        if ($appsToInstall.Count -gt 0) {
            foreach ($id in $appsToInstall) { Write-Log "Installing $id..."; Start-Process winget -ArgumentList "install -e --id $id --accept-package-agreements" -Wait; Write-Log "$id Done." }
            Write-Log "All installations completed."
        } else { Write-Log "No apps selected." }
    })
} else {
    $lblErr = New-Object System.Windows.Forms.Label; $lblErr.Text = "apps.json not found or empty! Please update the file."; $lblErr.ForeColor="Red"; $lblErr.Location = New-Object System.Drawing.Point(20,20); $lblErr.AutoSize=$true; $tabShop.Controls.Add($lblErr)
}

# ==============================================================================
# TAB 4: USER MANAGER (Mevcut)
# ==============================================================================
$lstUsers = New-Object System.Windows.Forms.ListBox; $lstUsers.Location = New-Object System.Drawing.Point(20, 80); $lstUsers.Size = New-Object System.Drawing.Size(300, 380); $tabUser.Controls.Add($lstUsers)
$btnScanUser = New-Object System.Windows.Forms.Button; $btnScanUser.Text = "List Local Users"; $btnScanUser.Location = New-Object System.Drawing.Point(20, 20); $btnScanUser.Size = New-Object System.Drawing.Size(300, 40); $btnScanUser.BackColor=$BtnColor; $tabUser.Controls.Add($btnScanUser)
$btnScanUser.Add_Click({ $lstUsers.Items.Clear(); try { $users = Get-LocalUser; foreach ($u in $users) { $st = if ($u.Enabled) {"(Active)"} else {"(Disabled)"}; $lstUsers.Items.Add("$($u.Name) $st") } } catch { Write-Log "Access Denied." } })

$btnResetPass = New-Object System.Windows.Forms.Button; $btnResetPass.Text = "Reset Password"; $btnResetPass.Location = New-Object System.Drawing.Point(340, 80); $btnResetPass.Size = New-Object System.Drawing.Size(200, 40); $btnResetPass.BackColor="#ffcccc"; $tabUser.Controls.Add($btnResetPass)
$btnResetPass.Add_Click({ if ($lstUsers.SelectedItem) { $username = $lstUsers.SelectedItem.Split(" ")[0]; $newPass = [Microsoft.VisualBasic.Interaction]::InputBox("New password for $($username):", "Reset", ""); if ($newPass) { try { $u = Get-LocalUser -Name $username; $u | Set-LocalUser -Password ($newPass | ConvertTo-SecureString -AsPlainText -Force); Write-Log "Password reset for $username." } catch { Write-Log "Error." } } } })

$btnUnlock = New-Object System.Windows.Forms.Button; $btnUnlock.Text = "Unlock Account"; $btnUnlock.Location = New-Object System.Drawing.Point(340, 130); $btnUnlock.Size = New-Object System.Drawing.Size(200, 40); $btnUnlock.BackColor=$BtnColor; $tabUser.Controls.Add($btnUnlock)
$btnUnlock.Add_Click({ if ($lstUsers.SelectedItem) { $username = $lstUsers.SelectedItem.Split(" ")[0]; try { Disable-LocalUser -Name $username; Enable-LocalUser -Name $username; Write-Log "$username Unlocked." } catch { Write-Log "Error." } } })

# ==============================================================================
# TAB 5: OFFICE & DEBLOAT & SECURITY & PRINT & MAINT & WINUPD (Klasik)
# ==============================================================================
# (Bu kısımlar v6.0 ile aynı kalabilir, sadece butonları ekliyorum)

# Office
$btnOutReset = New-Object System.Windows.Forms.Button; $btnOutReset.Text = "Reset Outlook Profile"; $btnOutReset.Location = New-Object System.Drawing.Point(20, 30); $btnOutReset.Size = New-Object System.Drawing.Size(250, 40); $btnOutReset.BackColor="#ffcccc"; $tabOffice.Controls.Add($btnOutReset)
$btnOutReset.Add_Click({ if(Test-Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\Outlook"){Remove-Item "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\Outlook" -Recurse -Force; Write-Log "Profile Deleted."} })

# Debloat
$btnDebloat = New-Object System.Windows.Forms.Button; $btnDebloat.Text = "Remove Xbox & Bing"; $btnDebloat.Location = New-Object System.Drawing.Point(20, 30); $btnDebloat.Size = New-Object System.Drawing.Size(300, 40); $btnDebloat.BackColor="#ffcccc"; $tabDebloat.Controls.Add($btnDebloat)
$btnDebloat.Add_Click({ Get-AppxPackage *xbox* | Remove-AppxPackage -ErrorAction SilentlyContinue; Get-AppxPackage *bing* | Remove-AppxPackage -ErrorAction SilentlyContinue; Write-Log "Debloated." })

# Security
$btnBit = New-Object System.Windows.Forms.Button; $btnBit.Text = "Check BitLocker"; $btnBit.Location = New-Object System.Drawing.Point(20, 20); $btnBit.Size = New-Object System.Drawing.Size(200, 40); $tabSec.Controls.Add($btnBit)
$txtSec = New-Object System.Windows.Forms.RichTextBox; $txtSec.Location = New-Object System.Drawing.Point(20, 80); $txtSec.Size = New-Object System.Drawing.Size(800, 300); $tabSec.Controls.Add($txtSec)
$btnBit.Add_Click({ try { $s = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop; $txtSec.Text = ($s | Out-String) } catch { $txtSec.Text = "Run as Admin." } })

# Printers
$btnScanPrint = New-Object System.Windows.Forms.Button; $btnScanPrint.Text = "Scan Printers"; $btnScanPrint.Location = New-Object System.Drawing.Point(20, 20); $btnScanPrint.Size = New-Object System.Drawing.Size(150, 40); $tabPrint.Controls.Add($btnScanPrint)
$lstPrint = New-Object System.Windows.Forms.ListBox; $lstPrint.Location = New-Object System.Drawing.Point(20, 80); $lstPrint.Size = New-Object System.Drawing.Size(400, 350); $tabPrint.Controls.Add($lstPrint)
$btnScanPrint.Add_Click({ $lstPrint.Items.Clear(); Get-Printer | ForEach-Object { $lstPrint.Items.Add($_.Name) } })

# Maint
$btnDrv = New-Object System.Windows.Forms.Button; $btnDrv.Text = "Backup Drivers (Desktop)"; $btnDrv.Location = New-Object System.Drawing.Point(20, 30); $btnDrv.Size = New-Object System.Drawing.Size(200, 40); $tabMaint.Controls.Add($btnDrv)
$btnDrv.Add_Click({ Export-WindowsDriver -Online -Destination "$env:USERPROFILE\Desktop\Drivers" -ErrorAction SilentlyContinue; Write-Log "Drivers Backed up." })

# WinUpd
$btnWinFix = New-Object System.Windows.Forms.Button; $btnWinFix.Text = "Nuke Update Cache"; $btnWinFix.Location = New-Object System.Drawing.Point(20, 30); $btnWinFix.Size = New-Object System.Drawing.Size(200, 40); $tabWinUpd.Controls.Add($btnWinFix)
$btnWinFix.Add_Click({ Stop-Service wuauserv; Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force; Start-Service wuauserv; Write-Log "Updates Reset." })


# ==============================================================================
# LOG BOX
# ==============================================================================
$logBox = New-Object System.Windows.Forms.RichTextBox; $logBox.Location = New-Object System.Drawing.Point(10, 540); $logBox.Size = New-Object System.Drawing.Size(1110, 180); $logBox.ReadOnly = $true; $logBox.BackColor = "Black"; $logBox.ForeColor = "#00FF00"; $logBox.Font = New-Object System.Drawing.Font("Consolas", 10); $form.Controls.Add($logBox)

Write-Log "LazyAdmin v7.0 NETWORK MASTER Edition Loaded..."
$form.ShowDialog()