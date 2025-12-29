Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic


$OnlineDbUrl = "https://gist.githubusercontent.com/mertfozzy/f2a38b4269d5d0c4cd0c57e2ceda1fe2/raw/b749afa9bc5902c7979a60c676fa704f8e7b4278/valid_keys.json" 
$LicenseFile = "$env:APPDATA\LazyAdminLicense.dat"

function Check-License {
    
    if (Test-Path $LicenseFile) {
        $SavedKey = Get-Content $LicenseFile
        if (-not [string]::IsNullOrWhiteSpace($SavedKey)) {
            return $true
        }
    }

    
    $UserKey = [Microsoft.VisualBasic.Interaction]::InputBox("Lutfen Lisans Key Giriniz:`n(Internet baglantisi gereklidir)", "LazyAdmin Aktivasyon", "")

    
    if ([string]::IsNullOrWhiteSpace($UserKey)) {
        [System.Windows.Forms.MessageBox]::Show("Anahtar girilmedi. Program kapatiliyor.", "Hata", 0, 16)
        [Environment]::Exit(0) # FİŞİ cEK
    }

    
    try {
        
        $RawData = Invoke-RestMethod -Uri $OnlineDbUrl -Method Get -ErrorAction Stop
        
        
        if ($RawData -is [string]) { 
            
            [System.Windows.Forms.MessageBox]::Show("Lisans sunucusundan gelen veri JSON formatinda degil! Linki kontrol et.`nGelen Veri Özeti: $($RawData.Substring(0, [math]::Min($RawData.Length, 50)))", "Sunucu Hatasi", 0, 16)
            [Environment]::Exit(0)
        }
        
        
        $CleanUserKey = $UserKey.Trim()
        $ValidKeys = $RawData | ForEach-Object { $_.Trim() }

   

        if ($ValidKeys -contains $CleanUserKey) {
            # BAŞARILI
            Set-Content -Path $LicenseFile -Value $CleanUserKey
            [System.Windows.Forms.MessageBox]::Show("Aktivasyon Basarili! Hosgeldiniz.", "Onaylandi", 0, 64)
            return $true
        } else {
            # BAŞARISIZ
            [System.Windows.Forms.MessageBox]::Show("Hatali Lisans Anahtari!`nGirdiginiz anahtar sistemde bulunamadi.", "Yetkisiz Giris", 0, 16)
            [Environment]::Exit(0) # FİŞİ cEK (Program kesinlikle kapanir)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Lisans sunucusuna baglanilamadi.`nİnternetinizi veya Gist Linkini kontrol edin.`nHata: $($_.Exception.Message)", "Baglanti Hatasi", 0, 16)
        [Environment]::Exit(0) # FİŞİ cEK
    }
    return $false
}

# --- BAŞLANGIc KONTROLÜ ---
# Eger fonksiyon $true döndürmezse program aninda ölür.
Check-License | Out-Null

# ... Buradan aşagisi senin normal kodlarin ...
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Linq
Add-Type -AssemblyName Microsoft.VisualBasic

# --- CONFIGURATION ---
$ScriptPath = $PSScriptRoot
$SettingsPath = "$ScriptPath\settings.json"
$JsonPath = "$ScriptPath\apps.json"

# Varsayilan Ayarlar
$AppName = "LazyAdmin v8.0 (Enterprise Gold)"
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

# Sekme Tanimlari
$tabDash   = New-Object System.Windows.Forms.TabPage; $tabDash.Text   = "Dashboard"
$tabNet    = New-Object System.Windows.Forms.TabPage; $tabNet.Text    = "Network++"
$tabShop   = New-Object System.Windows.Forms.TabPage; $tabShop.Text   = "App Shop"
$tabUser   = New-Object System.Windows.Forms.TabPage; $tabUser.Text   = "User Mgr"
$tabOffice = New-Object System.Windows.Forms.TabPage; $tabOffice.Text = "Office 365"
$tabDebloat= New-Object System.Windows.Forms.TabPage; $tabDebloat.Text= "Debloat"
$tabSec    = New-Object System.Windows.Forms.TabPage; $tabSec.Text    = "Security"
$tabPrint  = New-Object System.Windows.Forms.TabPage; $tabPrint.Text  = "Printers"
$tabWinUpd = New-Object System.Windows.Forms.TabPage; $tabWinUpd.Text = "Win Update"
$tabMaint  = New-Object System.Windows.Forms.TabPage; $tabMaint.Text  = "Maint."
$tabLogs   = New-Object System.Windows.Forms.TabPage; $tabLogs.Text   = "Deep Logs"
$tabRemote = New-Object System.Windows.Forms.TabPage; $tabRemote.Text = "Remote"

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
$tabControl.Controls.Add($tabLogs)
$tabControl.Controls.Add($tabRemote)

# ==============================================================================
# TAB 1: DASHBOARD (v5 Style - Detailed) 📊
# ==============================================================================
$grpInfo = New-Object System.Windows.Forms.GroupBox; $grpInfo.Text = "System Overview"; $grpInfo.Location = New-Object System.Drawing.Point(10, 10); $grpInfo.Size = New-Object System.Drawing.Size(1080, 460); $tabDash.Controls.Add($grpInfo)
$lblInfo = New-Object System.Windows.Forms.Label; $lblInfo.Location = New-Object System.Drawing.Point(20, 30); $lblInfo.Size = New-Object System.Drawing.Size(1040, 420); $lblInfo.Font = New-Object System.Drawing.Font("Consolas", 10); $grpInfo.Controls.Add($lblInfo)

function Refresh-Dashboard {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $bios = Get-CimInstance Win32_BIOS
        $cs = Get-CimInstance Win32_ComputerSystem
        $disk = Get-Volume -DriveLetter C
        $freeSpace = [math]::Round($disk.SizeRemaining / 1GB, 1)
        $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $uptime = (Get-Date) - $os.LastBootUpTime
        
        # Public IP (Timeoutlu)
        try { $pubIP = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 2 } catch { $pubIP = "Offline/Timeout" }

        $infoText = "COMPUTER NAME : $($env:COMPUTERNAME) `nUSER          : $($env:USERNAME) `nSERIAL (BIOS) : $($bios.SerialNumber) `nMODEL         : $($cs.Manufacturer) - $($cs.Model) `nOS VERSION    : $($os.Caption) `nPUBLIC IP     : $pubIP `n`nFREE DISK (C) : $freeSpace GB `nTOTAL RAM     : $totalRam GB `nUPTIME        : $([math]::Round($uptime.TotalHours, 1)) Hours `n`n--- DISK HEALTH ---`n"
        $infoText2 = "HOSTNAME      : $($env:COMPUTERNAME) `nCURRENT USER  : $($env:USERNAME) `nMODEL         : $($cs.Manufacturer) - $($cs.Model)`nSERIAL (BIOS) : $($bios.SerialNumber) `nOS VERSION    : $($os.Caption) `n`nDISK FREE (C) : $freeSpace GB `nTOTAL RAM     : $totalRam GB `nLAST BOOT     : $($os.LastBootUpTime) `n`n--- IP CONFIGURATION ---`n"

        $phyDisks = Get-CimInstance -Namespace root\Microsoft\Windows\Storage -ClassName MSFT_PhysicalDisk
        foreach ($d in $phyDisks) { $infoText += "DISK: $($d.FriendlyName) | HEALTH: $($d.HealthStatus) | MEDIA: $($d.MediaType) `n" }

        $ips = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.InterfaceAlias -notlike '*Loopback*' }
        foreach ($ip in $ips) { $infoText2 += "Interface: $($ip.InterfaceAlias) -> IP: $($ip.IPAddress) `n" }
        
        $lblInfo.Text = $infoText + $infoText2
    } catch { $lblInfo.Text = "Error fetching dashboard info." }
}
Refresh-Dashboard

# ==============================================================================
# TAB 2: NETWORK (Aynen Korundu) 🌐
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

$btnRenew = New-Object System.Windows.Forms.Button; $btnRenew.Text = "Release / Renew IP"; $btnRenew.Location = New-Object System.Drawing.Point(150, 30); $btnRenew.Size = New-Object System.Drawing.Size(120, 40); $btnRenew.BackColor=$BtnColor; $grpNetFix.Controls.Add($btnRenew)
$btnRenew.Add_Click({ Write-Log "Releasing & Renewing IP..."; Start-Process cmd -ArgumentList "/c ipconfig /release & ipconfig /renew" -Verb RunAs -WindowStyle Hidden; Write-Log "Done." })

$btnResetNet = New-Object System.Windows.Forms.Button; $btnResetNet.Text = "(!) Reset TCP/IP Stack"; $btnResetNet.Location = New-Object System.Drawing.Point(20, 80); $btnResetNet.Size = New-Object System.Drawing.Size(250, 40); $btnResetNet.BackColor="#ffcccc"; $grpNetFix.Controls.Add($btnResetNet)
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

# Port Tester (Alt Kisim)
$lblPort = New-Object System.Windows.Forms.Label; $lblPort.Text = "Port Tester:"; $lblPort.Location = New-Object System.Drawing.Point(20, 200); $lblPort.AutoSize=$true; $tabNet.Controls.Add($lblPort)
$txtPort = New-Object System.Windows.Forms.TextBox; $txtPort.Location = New-Object System.Drawing.Point(100, 197); $txtPort.Size = New-Object System.Drawing.Size(200, 20); $txtPort.Text="google.com:443"; $tabNet.Controls.Add($txtPort)
$btnPort = New-Object System.Windows.Forms.Button; $btnPort.Text = "Test Port"; $btnPort.Location = New-Object System.Drawing.Point(310, 195); $btnPort.Size = New-Object System.Drawing.Size(100, 25); $btnPort.BackColor=$BtnColor; $tabNet.Controls.Add($btnPort)
$btnPort.Add_Click({
    $pArr = $txtPort.Text.Split(":")
    if ($pArr.Count -eq 2) { try { $t = Test-NetConnection -ComputerName $pArr[0] -Port $pArr[1] -WarningAction SilentlyContinue; if ($t.TcpTestSucceeded) { Write-Log "OPEN: $($txtPort.Text)" } else { Write-Log "CLOSED: $($txtPort.Text)" } } catch { Write-Log "Error." } }
})

# ==============================================================================
# TAB 3: APP SHOP (Aynen Korundu) 🛒
# ==============================================================================
if (-not (Test-Path $JsonPath)) { try { $AppsList = Invoke-RestMethod -Uri "apps.json" -ErrorAction SilentlyContinue } catch {} } else { $RawJson = Get-Content $JsonPath -Raw -Encoding UTF8; $AppsList = $RawJson | ConvertFrom-Json }
if ($AppsList) {
    $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $flowPanel.Dock = "Top"; $flowPanel.Height = 400; $flowPanel.AutoScroll = $true; $tabShop.Controls.Add($flowPanel)
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "INSTALL SELECTED APPS (WINGET)"; $btnInstall.Location = New-Object System.Drawing.Point(20, 420); $btnInstall.Size = New-Object System.Drawing.Size(900,40); $btnInstall.BackColor="#007acc"; $btnInstall.ForeColor="White"; $tabShop.Controls.Add($btnInstall)
    $Categories = $AppsList | Select-Object -ExpandProperty Category -Unique
    foreach ($cat in $Categories) {
        $grp = New-Object System.Windows.Forms.GroupBox; $grp.Text = $cat; $grp.Size = New-Object System.Drawing.Size(220, 250); $grp.BackColor="White"; $grp.Margin = New-Object System.Windows.Forms.Padding(5); $flowPanel.Controls.Add($grp)
        $myApps = $AppsList | Where-Object { $_.Category -eq $cat }; $y = 20
        foreach ($app in $myApps) { $c = New-Object System.Windows.Forms.CheckBox; $c.Text=$app.Name; $c.Tag=$app.Id; $c.Location=New-Object System.Drawing.Point(10,$y); $c.AutoSize=$true; $tt = New-Object System.Windows.Forms.ToolTip; $tt.SetToolTip($c, $app.Description); $grp.Controls.Add($c); $y+=25 }
    }
    $btnInstall.Add_Click({ $appsToInstall = @(); foreach ($group in $flowPanel.Controls) { foreach ($ctrl in $group.Controls) { if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Checked) { $appsToInstall += $ctrl.Tag } } }; if ($appsToInstall.Count -gt 0) { foreach ($id in $appsToInstall) { Write-Log "Installing $id..."; Start-Process winget -ArgumentList "install -e --id $id --accept-package-agreements" -Wait; Write-Log "$id Done." } } })
}

# ==============================================================================
# TAB 4: USER MANAGER (Aynen Korundu) 👤
# ==============================================================================
$lstUsers = New-Object System.Windows.Forms.ListBox; $lstUsers.Location = New-Object System.Drawing.Point(20, 80); $lstUsers.Size = New-Object System.Drawing.Size(300, 380); $tabUser.Controls.Add($lstUsers)
$btnScanUser = New-Object System.Windows.Forms.Button; $btnScanUser.Text = "List Local Users"; $btnScanUser.Location = New-Object System.Drawing.Point(20, 20); $btnScanUser.Size = New-Object System.Drawing.Size(300, 40); $btnScanUser.BackColor=$BtnColor; $tabUser.Controls.Add($btnScanUser)
$btnScanUser.Add_Click({ $lstUsers.Items.Clear(); try { $users = Get-LocalUser; foreach ($u in $users) { $st = if ($u.Enabled) {"(Active)"} else {"(Disabled)"}; $lstUsers.Items.Add("$($u.Name) $st") } } catch { Write-Log "Access Denied." } })
$btnResetPass = New-Object System.Windows.Forms.Button; $btnResetPass.Text = "Reset Password"; $btnResetPass.Location = New-Object System.Drawing.Point(340, 80); $btnResetPass.Size = New-Object System.Drawing.Size(200, 40); $btnResetPass.BackColor="#ffcccc"; $tabUser.Controls.Add($btnResetPass)
$btnResetPass.Add_Click({ if ($lstUsers.SelectedItem) { $username = $lstUsers.SelectedItem.Split(" ")[0]; $newPass = [Microsoft.VisualBasic.Interaction]::InputBox("New password for $($username):", "Reset", ""); if ($newPass) { try { $u = Get-LocalUser -Name $username; $u | Set-LocalUser -Password ($newPass | ConvertTo-SecureString -AsPlainText -Force); Write-Log "Password reset for $username." } catch { Write-Log "Error." } } } })
$btnUnlock = New-Object System.Windows.Forms.Button; $btnUnlock.Text = "Unlock Account"; $btnUnlock.Location = New-Object System.Drawing.Point(340, 130); $btnUnlock.Size = New-Object System.Drawing.Size(200, 40); $btnUnlock.BackColor=$BtnColor; $tabUser.Controls.Add($btnUnlock)
$btnUnlock.Add_Click({ if ($lstUsers.SelectedItem) { $username = $lstUsers.SelectedItem.Split(" ")[0]; try { Disable-LocalUser -Name $username; Enable-LocalUser -Name $username; Write-Log "$username Unlocked." } catch { Write-Log "Error." } } })

# ==============================================================================
# TAB 5: OFFICE & 365 (DOLDURULDU) 📧
# ==============================================================================
$grpFix = New-Object System.Windows.Forms.GroupBox; $grpFix.Text = "Repair & Reset"; $grpFix.Location = New-Object System.Drawing.Point(20, 20); $grpFix.Size = New-Object System.Drawing.Size(300, 200); $tabOffice.Controls.Add($grpFix)
$btnOutReset = New-Object System.Windows.Forms.Button; $btnOutReset.Text = "Reset Outlook Profile"; $btnOutReset.Location = New-Object System.Drawing.Point(20, 30); $btnOutReset.Size = New-Object System.Drawing.Size(250, 40); $btnOutReset.BackColor="#ffcccc"; $grpFix.Controls.Add($btnOutReset)
$btnOutReset.Add_Click({ if(Test-Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\Outlook"){Remove-Item "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\Outlook" -Recurse -Force; Write-Log "Outlook Profile Deleted."} else {Write-Log "Profile not found."} })
$btnOffRep = New-Object System.Windows.Forms.Button; $btnOffRep.Text = "Office Quick Repair"; $btnOffRep.Location = New-Object System.Drawing.Point(20, 80); $btnOffRep.Size = New-Object System.Drawing.Size(250, 40); $btnOffRep.BackColor=$BtnColor; $grpFix.Controls.Add($btnOffRep)
$btnOffRep.Add_Click({ $path="C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"; if(Test-Path $path){Start-Process $path -ArgumentList "scenario=Repair", "platform=x64", "culture=en-us", "RepairType=QuickRepair", "DisplayLevel=True"} })
$btnTeams = New-Object System.Windows.Forms.Button; $btnTeams.Text = "Clear Teams Cache"; $btnTeams.Location = New-Object System.Drawing.Point(20, 130); $btnTeams.Size = New-Object System.Drawing.Size(250, 40); $btnTeams.BackColor=$BtnColor; $grpFix.Controls.Add($btnTeams)
$btnTeams.Add_Click({ Stop-Process -Name "ms-teams","Teams" -Force -ErrorAction SilentlyContinue; Remove-Item "$env:USERPROFILE\appdata\roaming\Microsoft\Teams\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Teams Cache Cleared." })

$grpSafe = New-Object System.Windows.Forms.GroupBox; $grpSafe.Text = "Safe Mode Launchers"; $grpSafe.Location = New-Object System.Drawing.Point(340, 20); $grpSafe.Size = New-Object System.Drawing.Size(300, 200); $tabOffice.Controls.Add($grpSafe)
$btnSafeOut = New-Object System.Windows.Forms.Button; $btnSafeOut.Text = "Outlook (Safe Mode)"; $btnSafeOut.Location = New-Object System.Drawing.Point(20, 30); $btnSafeOut.Size = New-Object System.Drawing.Size(250, 40); $btnSafeOut.BackColor=$BtnColor; $grpSafe.Controls.Add($btnSafeOut)
$btnSafeOut.Add_Click({ Start-Process "outlook.exe" -ArgumentList "/safe"; Write-Log "Outlook Safe Mode Launched." })
$btnSafeExcel = New-Object System.Windows.Forms.Button; $btnSafeExcel.Text = "Excel (Safe Mode)"; $btnSafeExcel.Location = New-Object System.Drawing.Point(20, 80); $btnSafeExcel.Size = New-Object System.Drawing.Size(250, 40); $btnSafeExcel.BackColor=$BtnColor; $grpSafe.Controls.Add($btnSafeExcel)
$btnSafeExcel.Add_Click({ Start-Process "excel.exe" -ArgumentList "/safe"; Write-Log "Excel Safe Mode Launched." })
$btnSafeWord = New-Object System.Windows.Forms.Button; $btnSafeWord.Text = "Word (Safe Mode)"; $btnSafeWord.Location = New-Object System.Drawing.Point(20, 130); $btnSafeWord.Size = New-Object System.Drawing.Size(250, 40); $btnSafeWord.BackColor=$BtnColor; $grpSafe.Controls.Add($btnSafeWord)
$btnSafeWord.Add_Click({ Start-Process "winword.exe" -ArgumentList "/safe"; Write-Log "Word Safe Mode Launched." })

# ==============================================================================
# TAB 6: DEBLOAT (GucLENDIRILDI) 🧹
# ==============================================================================
$grpDebloat = New-Object System.Windows.Forms.GroupBox; $grpDebloat.Text = "Select Junk to Remove"; $grpDebloat.Location = New-Object System.Drawing.Point(20, 20); $grpDebloat.Size = New-Object System.Drawing.Size(400, 350); $tabDebloat.Controls.Add($grpDebloat)
$chkXbox = New-Object System.Windows.Forms.CheckBox; $chkXbox.Text = "Xbox Apps"; $chkXbox.Location = New-Object System.Drawing.Point(20, 50); $chkXbox.AutoSize=$true; $grpDebloat.Controls.Add($chkXbox)
$chkBing = New-Object System.Windows.Forms.CheckBox; $chkBing.Text = "Bing Weather"; $chkBing.Location = New-Object System.Drawing.Point(20, 80); $chkXbox.AutoSize=$true; $grpDebloat.Controls.Add($chkBing)
$chkCortana = New-Object System.Windows.Forms.CheckBox; $chkCortana.Text = "Cortana"; $chkCortana.Location = New-Object System.Drawing.Point(20, 110); $chkXbox.AutoSize=$true; $grpDebloat.Controls.Add($chkCortana)
$chkTips = New-Object System.Windows.Forms.CheckBox; $chkTips.Text = "Tips/People Bar"; $chkTips.Location = New-Object System.Drawing.Point(20, 140); $chkXbox.AutoSize=$true; $grpDebloat.Controls.Add($chkTips)
$chkOneDrive = New-Object System.Windows.Forms.CheckBox; $chkOneDrive.Text = "OneDrive"; $chkOneDrive.Location = New-Object System.Drawing.Point(20, 170); $chkXbox.AutoSize=$true; $grpDebloat.Controls.Add($chkOneDrive)

$btnNuke = New-Object System.Windows.Forms.Button; $btnNuke.Text = "EXECUTE DEBLOAT"; $btnNuke.Location = New-Object System.Drawing.Point(20, 220); $btnNuke.Size = New-Object System.Drawing.Size(350, 50); $btnNuke.BackColor="#ffcccc"; $grpDebloat.Controls.Add($btnNuke)
$btnNuke.Add_Click({
    if ($chkXbox.Checked) { Write-Log "Killing Xbox..."; Get-AppxPackage *xbox* | Remove-AppxPackage -ErrorAction SilentlyContinue }
    if ($chkBing.Checked) { Write-Log "Killing Bing..."; Get-AppxPackage *bing* | Remove-AppxPackage -ErrorAction SilentlyContinue }
    if ($chkCortana.Checked) { Write-Log "Killing Cortana..."; Get-AppxPackage *cortana* | Remove-AppxPackage -ErrorAction SilentlyContinue }
    if ($chkTips.Checked) { Write-Log "Killing Tips..."; Get-AppxPackage *tips* | Remove-AppxPackage -ErrorAction SilentlyContinue }
    if ($chkOneDrive.Checked) { Write-Log "Stopping OneDrive..."; Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue; Write-Log "Uninstalling..."; Start-Process "$env:systemroot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait }
    Write-Log "Debloat Cycle Complete."
})

$btnBrowsers = New-Object System.Windows.Forms.Button; $btnBrowsers.Text = "Clean All Browsers Cache"; $btnBrowsers.Location = New-Object System.Drawing.Point(460, 30); $btnBrowsers.Size = New-Object System.Drawing.Size(300, 50); $btnBrowsers.BackColor=$BtnColor; $tabDebloat.Controls.Add($btnBrowsers)
$btnBrowsers.Add_Click({
    Stop-Process -Name "chrome","msedge","firefox" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Browsers Cleaned."
})

# ==============================================================================
# TAB 7: SECURITY (DOLDURULDU) 🛡️
# ==============================================================================
$grpSecCheck = New-Object System.Windows.Forms.GroupBox; $grpSecCheck.Text = "Security Audit"; $grpSecCheck.Location = New-Object System.Drawing.Point(20, 20); $grpSecCheck.Size = New-Object System.Drawing.Size(300, 250); $tabSec.Controls.Add($grpSecCheck)
$btnBit = New-Object System.Windows.Forms.Button; $btnBit.Text = "BitLocker Status"; $btnBit.Location = New-Object System.Drawing.Point(20, 30); $btnBit.Size = New-Object System.Drawing.Size(250, 40); $btnBit.BackColor=$BtnColor; $grpSecCheck.Controls.Add($btnBit)
$btnBit.Add_Click({ try { $s = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop | Select-Object MountPoint, ProtectionStatus, EncryptionPercentage; $txtSec.Text = ($s | Out-String) } catch { $txtSec.Text = "Run as Admin." } })
$btnFw = New-Object System.Windows.Forms.Button; $btnFw.Text = "Firewall Status"; $btnFw.Location = New-Object System.Drawing.Point(20, 80); $btnFw.Size = New-Object System.Drawing.Size(250, 40); $btnFw.BackColor=$BtnColor; $grpSecCheck.Controls.Add($btnFw)
$btnFw.Add_Click({ $f = netsh advfirewall show allprofiles; $txtSec.Text = ($f | Out-String) })
$btnDef = New-Object System.Windows.Forms.Button; $btnDef.Text = "Defender Status"; $btnDef.Location = New-Object System.Drawing.Point(20, 130); $btnDef.Size = New-Object System.Drawing.Size(250, 40); $btnDef.BackColor=$BtnColor; $grpSecCheck.Controls.Add($btnDef)
$btnDef.Add_Click({ try { $d = Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, AMServiceEnabled; $txtSec.Text = ($d | Out-String) } catch { $txtSec.Text = "Err" } })

$txtSec = New-Object System.Windows.Forms.RichTextBox; $txtSec.Location = New-Object System.Drawing.Point(340, 30); $txtSec.Size = New-Object System.Drawing.Size(700, 400); $txtSec.Font = New-Object System.Drawing.Font("Consolas", 9); $tabSec.Controls.Add($txtSec)

# ==============================================================================
# TAB 8: PRINTERS (DOLDURULDU) 🖨️
# ==============================================================================
$lstPrint = New-Object System.Windows.Forms.ListBox; $lstPrint.Location = New-Object System.Drawing.Point(20, 20); $lstPrint.Size = New-Object System.Drawing.Size(300, 400); $tabPrint.Controls.Add($lstPrint)
$grpPrintActs = New-Object System.Windows.Forms.GroupBox; $grpPrintActs.Text = "Actions"; $grpPrintActs.Location = New-Object System.Drawing.Point(340, 20); $grpPrintActs.Size = New-Object System.Drawing.Size(300, 400); $tabPrint.Controls.Add($grpPrintActs)

$btnScanPrint = New-Object System.Windows.Forms.Button; $btnScanPrint.Text = "1. Scan Printers"; $btnScanPrint.Location = New-Object System.Drawing.Point(20, 30); $btnScanPrint.Size = New-Object System.Drawing.Size(250, 40); $btnScanPrint.BackColor=$BtnColor; $grpPrintActs.Controls.Add($btnScanPrint)
$btnScanPrint.Add_Click({ $lstPrint.Items.Clear(); Get-Printer | ForEach-Object { $lstPrint.Items.Add($_.Name) } })

$btnSetDef = New-Object System.Windows.Forms.Button; $btnSetDef.Text = "2. Set as Default"; $btnSetDef.Location = New-Object System.Drawing.Point(20, 80); $btnSetDef.Size = New-Object System.Drawing.Size(250, 40); $btnSetDef.BackColor=$BtnColor; $grpPrintActs.Controls.Add($btnSetDef)
$btnSetDef.Add_Click({ if ($lstPrint.SelectedItem) { (Get-WmiObject Win32_Printer -Filter "Name='$($lstPrint.SelectedItem)'").SetDefaultPrinter(); Write-Log "Default Printer Set." } })

$btnTestP = New-Object System.Windows.Forms.Button; $btnTestP.Text = "3. Print Test Page"; $btnTestP.Location = New-Object System.Drawing.Point(20, 130); $btnTestP.Size = New-Object System.Drawing.Size(250, 40); $btnTestP.BackColor=$BtnColor; $grpPrintActs.Controls.Add($btnTestP)
$btnTestP.Add_Click({ if ($lstPrint.SelectedItem) { (Get-WmiObject Win32_Printer -Filter "Name='$($lstPrint.SelectedItem)'").PrintTestPage(); Write-Log "Test Page Sent." } })

$btnSpool = New-Object System.Windows.Forms.Button; $btnSpool.Text = "Fix Spooler Service"; $btnSpool.Location = New-Object System.Drawing.Point(20, 200); $btnSpool.Size = New-Object System.Drawing.Size(250, 40); $btnSpool.BackColor="#ffebcd"; $grpPrintActs.Controls.Add($btnSpool)
$btnSpool.Add_Click({ Restart-Service Spooler -Force; Write-Log "Spooler Restarted." })

$btnOldUI = New-Object System.Windows.Forms.Button; $btnOldUI.Text = "Open Devices & Printers (Old)"; $btnOldUI.Location = New-Object System.Drawing.Point(20, 250); $btnOldUI.Size = New-Object System.Drawing.Size(250, 40); $btnOldUI.BackColor=$BtnColor; $grpPrintActs.Controls.Add($btnOldUI)
$btnOldUI.Add_Click({ Start-Process "control" -ArgumentList "printers" })

# ==============================================================================
# TAB 9: WIN UPDATE (DOLDURULDU) 🔄
# ==============================================================================
$grpWinAct = New-Object System.Windows.Forms.GroupBox; $grpWinAct.Text = "Actions"; $grpWinAct.Location = New-Object System.Drawing.Point(20, 20); $grpWinAct.Size = New-Object System.Drawing.Size(300, 200); $tabWinUpd.Controls.Add($grpWinAct)
$btnCheckUpd = New-Object System.Windows.Forms.Button; $btnCheckUpd.Text = "Check for Updates (UI)"; $btnCheckUpd.Location = New-Object System.Drawing.Point(20, 30); $btnCheckUpd.Size = New-Object System.Drawing.Size(250, 40); $btnCheckUpd.BackColor=$BtnColor; $grpWinAct.Controls.Add($btnCheckUpd)
$btnCheckUpd.Add_Click({ Start-Process "ms-settings:windowsupdate-action" })
$btnHist = New-Object System.Windows.Forms.Button; $btnHist.Text = "View Update History"; $btnHist.Location = New-Object System.Drawing.Point(20, 80); $btnHist.Size = New-Object System.Drawing.Size(250, 40); $btnHist.BackColor=$BtnColor; $grpWinAct.Controls.Add($btnHist)
$btnHist.Add_Click({ Start-Process "ms-settings:windowsupdate-history" })

$grpWinFix = New-Object System.Windows.Forms.GroupBox; $grpWinFix.Text = "Emergency Fixes"; $grpWinFix.Location = New-Object System.Drawing.Point(340, 20); $grpWinFix.Size = New-Object System.Drawing.Size(300, 200); $tabWinUpd.Controls.Add($grpWinFix)
$btnWinFix = New-Object System.Windows.Forms.Button; $btnWinFix.Text = "Nuke Update Cache (Fix)"; $btnWinFix.Location = New-Object System.Drawing.Point(20, 30); $btnWinFix.Size = New-Object System.Drawing.Size(250, 40); $btnWinFix.BackColor="#ffcccc"; $grpWinFix.Controls.Add($btnWinFix)
$btnWinFix.Add_Click({ Stop-Service wuauserv -Force; Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force; Start-Service wuauserv; Write-Log "Update Cache Cleared." })
$btnPause = New-Object System.Windows.Forms.Button; $btnPause.Text = "Pause Updates (7 Days)"; $btnPause.Location = New-Object System.Drawing.Point(20, 80); $btnPause.Size = New-Object System.Drawing.Size(250, 40); $btnPause.BackColor=$BtnColor; $grpWinFix.Controls.Add($btnPause)
$btnPause.Add_Click({ Start-Process "ms-settings:windowsupdate" }) # PowerShell ile pause zor, UI aciyoruz

# ==============================================================================
# TAB 10: MAINTENANCE (DOLDURULDU) 🛠️
# ==============================================================================
$grpSysMaint = New-Object System.Windows.Forms.GroupBox; $grpSysMaint.Text = "System Maintenance"; $grpSysMaint.Location = New-Object System.Drawing.Point(20, 20); $grpSysMaint.Size = New-Object System.Drawing.Size(300, 300); $tabMaint.Controls.Add($grpSysMaint)
$btnCleanMgr = New-Object System.Windows.Forms.Button; $btnCleanMgr.Text = "Disk Cleanup (Cleanmgr)"; $btnCleanMgr.Location = New-Object System.Drawing.Point(20, 30); $btnCleanMgr.Size = New-Object System.Drawing.Size(250, 40); $btnCleanMgr.BackColor=$BtnColor; $grpSysMaint.Controls.Add($btnCleanMgr)
$btnCleanMgr.Add_Click({ Start-Process "cleanmgr.exe" })
$btnSFC = New-Object System.Windows.Forms.Button; $btnSFC.Text = "System File Checker (SFC)"; $btnSFC.Location = New-Object System.Drawing.Point(20, 80); $btnSFC.Size = New-Object System.Drawing.Size(250, 40); $btnSFC.BackColor=$BtnColor; $grpSysMaint.Controls.Add($btnSFC)
$btnSFC.Add_Click({ Start-Process powershell -ArgumentList "-NoExit", "-Command", "sfc /scannow" -Verb RunAs })
$btnDefrag = New-Object System.Windows.Forms.Button; $btnDefrag.Text = "Defrag / Optimize Drives"; $btnDefrag.Location = New-Object System.Drawing.Point(20, 130); $btnDefrag.Size = New-Object System.Drawing.Size(250, 40); $btnDefrag.BackColor=$BtnColor; $grpSysMaint.Controls.Add($btnDefrag)
$btnDefrag.Add_Click({ Start-Process "dfrgui.exe" })

$grpTools = New-Object System.Windows.Forms.GroupBox; $grpTools.Text = "Tools & Backup"; $grpTools.Location = New-Object System.Drawing.Point(340, 20); $grpTools.Size = New-Object System.Drawing.Size(300, 300); $tabMaint.Controls.Add($grpTools)
$btnDrv = New-Object System.Windows.Forms.Button; $btnDrv.Text = "Backup Drivers (Desktop)"; $btnDrv.Location = New-Object System.Drawing.Point(20, 30); $btnDrv.Size = New-Object System.Drawing.Size(250, 40); $btnDrv.BackColor=$BtnColor; $grpTools.Controls.Add($btnDrv)
$btnDrv.Add_Click({ Export-WindowsDriver -Online -Destination "$env:USERPROFILE\Desktop\Drivers" -ErrorAction SilentlyContinue; Write-Log "Drivers Backed up." })
$btnGod = New-Object System.Windows.Forms.Button; $btnGod.Text = "Create God Mode Icon"; $btnGod.Location = New-Object System.Drawing.Point(20, 80); $btnGod.Size = New-Object System.Drawing.Size(250, 40); $btnGod.BackColor=$BtnColor; $grpTools.Controls.Add($btnGod)
$btnGod.Add_Click({ New-Item -Path "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -ItemType Directory -Force; Write-Log "God Mode created." })
$btnRestore = New-Object System.Windows.Forms.Button; $btnRestore.Text = "Create Restore Point"; $btnRestore.Location = New-Object System.Drawing.Point(20, 130); $btnRestore.Size = New-Object System.Drawing.Size(250, 40); $btnRestore.BackColor="#ffebcd"; $grpTools.Controls.Add($btnRestore)
$btnRestore.Add_Click({ Checkpoint-Computer -Description "LazyAdmin Manual Point" -RestorePointType "MODIFY_SETTINGS"; Write-Log "Restore Point Created." })

# ==============================================================================
# TAB 11: DEEP LOGS
# ==============================================================================
$txtLogs = New-Object System.Windows.Forms.RichTextBox; $txtLogs.Location = New-Object System.Drawing.Point(20, 80); $txtLogs.Size = New-Object System.Drawing.Size(1000, 350); $txtLogs.Font = New-Object System.Drawing.Font("Consolas", 9); $txtLogs.BackColor="Black"; $txtLogs.ForeColor="#00ff00"; $tabLogs.Controls.Add($txtLogs)
$btnBsod = New-Object System.Windows.Forms.Button; $btnBsod.Text = "Check Critical Errors"; $btnBsod.Location = New-Object System.Drawing.Point(20, 20); $btnBsod.Size = New-Object System.Drawing.Size(200, 40); $btnBsod.BackColor="White"; $tabLogs.Controls.Add($btnBsod)
$btnBsod.Add_Click({ $errs = Get-EventLog -LogName System -EntryType Error,Warning -Newest 10 -ErrorAction SilentlyContinue | Where-Object { $_.EventID -eq 41 -or $_.EventID -eq 6008 }; $txtLogs.Text = if ($errs) { $errs | Out-String } else { "No critical errors found." } })

# ==============================================================================
# TAB 12: REMOTE TOOLS
# ==============================================================================
$lblTarget = New-Object System.Windows.Forms.Label; $lblTarget.Text = "Target IP:"; $lblTarget.Location = New-Object System.Drawing.Point(20, 30); $lblTarget.AutoSize=$true; $tabRemote.Controls.Add($lblTarget)
$txtTarget = New-Object System.Windows.Forms.TextBox; $txtTarget.Location = New-Object System.Drawing.Point(100, 27); $txtTarget.Size = New-Object System.Drawing.Size(200, 20); $tabRemote.Controls.Add($txtTarget)

$btnRDP = New-Object System.Windows.Forms.Button; $btnRDP.Text = "Launch RDP"; $btnRDP.Location = New-Object System.Drawing.Point(20, 70); $btnRDP.Size = New-Object System.Drawing.Size(120, 40); $btnRDP.BackColor="White"; $tabRemote.Controls.Add($btnRDP)
$btnRDP.Add_Click({ if ($txtTarget.Text) { Start-Process "mstsc.exe" -ArgumentList "/v:$($txtTarget.Text)" } })

$btnCShare = New-Object System.Windows.Forms.Button; $btnCShare.Text = "Open C$"; $btnCShare.Location = New-Object System.Drawing.Point(150, 70); $btnCShare.Size = New-Object System.Drawing.Size(120, 40); $btnCShare.BackColor="White"; $tabRemote.Controls.Add($btnCShare)
$btnCShare.Add_Click({ if ($txtTarget.Text) { Invoke-Item "\\$($txtTarget.Text)\c$" } })

# ==============================================================================
# LOG BOX
# ==============================================================================
$logBox = New-Object System.Windows.Forms.RichTextBox; $logBox.Location = New-Object System.Drawing.Point(10, 540); $logBox.Size = New-Object System.Drawing.Size(1110, 180); $logBox.ReadOnly = $true; $logBox.BackColor = "Black"; $logBox.ForeColor = "#00FF00"; $logBox.Font = New-Object System.Drawing.Font("Consolas", 10); $form.Controls.Add($logBox)

Write-Log "LazyAdmin v8.0 ENTERPRISE GOLD Loaded."
$form.ShowDialog()