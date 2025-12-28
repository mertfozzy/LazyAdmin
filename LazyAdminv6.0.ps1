Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Linq
Add-Type -AssemblyName Microsoft.VisualBasic

# --- CONFIGURATION (WHITE LABEL) ---
$ScriptPath = $PSScriptRoot
$SettingsPath = "$ScriptPath\settings.json"
$JsonPath = "$ScriptPath\apps.json"

# Varsayılan Ayarlar (Eğer JSON yoksa)
$AppName = "LazyAdmin v6.0 (Enterprise)"
$MainColor = "#f0f0f0" # Arka plan
$BtnColor = "White"

# Ayarları JSON'dan Oku
if (Test-Path $SettingsPath) {
    try {
        $Settings = Get-Content $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $AppName = $Settings.AppName
        $MainColor = $Settings.SecondaryColor 
    } catch { Write-Host "JSON Hatası, varsayılanlar kullanılıyor." }
}

# --- MAIN FORM SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = $AppName
$form.Size = New-Object System.Drawing.Size(1150, 780)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = $MainColor

# --- LOG FUNCTION ---
function Write-Log($message) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logBox.AppendText("[$timestamp] $message `n")
    $logBox.ScrollToCaret()
}

# --- TABS SETUP ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(1110, 520)
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$tabControl.SizeMode = "FillToRight"
$form.Controls.Add($tabControl)

# Sekmeleri Tanımla
$tabDash   = New-Object System.Windows.Forms.TabPage; $tabDash.Text   = "Dashboard"
$tabUser   = New-Object System.Windows.Forms.TabPage; $tabUser.Text   = "User Mgr"   
$tabOffice = New-Object System.Windows.Forms.TabPage; $tabOffice.Text = "Office 365"
$tabDebloat= New-Object System.Windows.Forms.TabPage; $tabDebloat.Text= "Debloat"    
$tabSec    = New-Object System.Windows.Forms.TabPage; $tabSec.Text    = "Security"
$tabPrint  = New-Object System.Windows.Forms.TabPage; $tabPrint.Text  = "Printers"
$tabWinUpd = New-Object System.Windows.Forms.TabPage; $tabWinUpd.Text = "Win Update"
$tabMaint  = New-Object System.Windows.Forms.TabPage; $tabMaint.Text  = "Maint."
$tabNet    = New-Object System.Windows.Forms.TabPage; $tabNet.Text    = "Network"
$tabShop   = New-Object System.Windows.Forms.TabPage; $tabShop.Text   = "App Shop"

$tabControl.Controls.Add($tabDash)
$tabControl.Controls.Add($tabUser)
$tabControl.Controls.Add($tabOffice)
$tabControl.Controls.Add($tabDebloat)
$tabControl.Controls.Add($tabSec)
$tabControl.Controls.Add($tabPrint)
$tabControl.Controls.Add($tabWinUpd)
$tabControl.Controls.Add($tabMaint)
$tabControl.Controls.Add($tabNet)
$tabControl.Controls.Add($tabShop)

# ==============================================================================
# TAB 1: DASHBOARD
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
# TAB 2: USER MANAGER (Fixed 🛠️)
# ==============================================================================
$lstUsers = New-Object System.Windows.Forms.ListBox; $lstUsers.Location = New-Object System.Drawing.Point(20, 80); $lstUsers.Size = New-Object System.Drawing.Size(300, 380); $tabUser.Controls.Add($lstUsers)

$btnScanUser = New-Object System.Windows.Forms.Button; $btnScanUser.Text = "List Local Users"; $btnScanUser.Location = New-Object System.Drawing.Point(20, 20); $btnScanUser.Size = New-Object System.Drawing.Size(300, 40); $btnScanUser.BackColor=$BtnColor; $tabUser.Controls.Add($btnScanUser)
$btnScanUser.Add_Click({
    $lstUsers.Items.Clear()
    try {
        $users = Get-LocalUser
        foreach ($u in $users) { $status = if ($u.Enabled) {"(Active)"} else {"(Disabled)"}; $lstUsers.Items.Add("$($u.Name) $status") }
    } catch { Write-Log "Error listing users. Run as Admin." }
})

$btnResetPass = New-Object System.Windows.Forms.Button; $btnResetPass.Text = "Reset Password"; $btnResetPass.Location = New-Object System.Drawing.Point(340, 80); $btnResetPass.Size = New-Object System.Drawing.Size(200, 40); $btnResetPass.BackColor="#ffcccc"; $tabUser.Controls.Add($btnResetPass)
$btnResetPass.Add_Click({
    $sel = $lstUsers.SelectedItem
    if ($sel) {
        $username = $sel.Split(" ")[0]
        # HATA BURADAYDI, DÜZELTİLDİ: $($username):
        $newPass = [Microsoft.VisualBasic.Interaction]::InputBox("Enter new password for $($username):", "Reset Password", "")
        if ($newPass) {
            try { 
                $u = Get-LocalUser -Name $username
                $u | Set-LocalUser -Password ($newPass | ConvertTo-SecureString -AsPlainText -Force)
                Write-Log "Password reset successfully for $username." 
            } 
            catch { Write-Log "Error resetting password. Ensure you are Admin." }
        }
    } else { Write-Log "Select a user first." }
})

$btnUnlock = New-Object System.Windows.Forms.Button; $btnUnlock.Text = "Unlock Account"; $btnUnlock.Location = New-Object System.Drawing.Point(340, 130); $btnUnlock.Size = New-Object System.Drawing.Size(200, 40); $btnUnlock.BackColor=$BtnColor; $tabUser.Controls.Add($btnUnlock)
$btnUnlock.Add_Click({
    $sel = $lstUsers.SelectedItem
    if ($sel) { 
        $username = $sel.Split(" ")[0]
        try { Disable-LocalUser -Name $username; Enable-LocalUser -Name $username; Write-Log "$username unlocked/refreshed." } catch { Write-Log "Error processing user." }
    }
})

# ==============================================================================
# TAB 3: OFFICE & 365
# ==============================================================================
$btnOutReset = New-Object System.Windows.Forms.Button; $btnOutReset.Text = "Reset Outlook Profile"; $btnOutReset.Location = New-Object System.Drawing.Point(20, 30); $btnOutReset.Size = New-Object System.Drawing.Size(250, 40); $btnOutReset.BackColor="#ffcccc"; $tabOffice.Controls.Add($btnOutReset)
$btnOutReset.Add_Click({ 
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\Outlook"
    if (Test-Path $regPath) { Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Outlook Profile Deleted." } else { Write-Log "Profile not found." }
})

$btnOffRep = New-Object System.Windows.Forms.Button; $btnOffRep.Text = "Run Office Quick Repair"; $btnOffRep.Location = New-Object System.Drawing.Point(20, 80); $btnOffRep.Size = New-Object System.Drawing.Size(250, 40); $btnOffRep.BackColor=$BtnColor; $tabOffice.Controls.Add($btnOffRep)
$btnOffRep.Add_Click({
    $officeClickToRun = "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"
    if (Test-Path $officeClickToRun) { Start-Process $officeClickToRun -ArgumentList "scenario=Repair", "platform=x64", "culture=en-us", "RepairType=QuickRepair", "DisplayLevel=True"; Write-Log "Repair launched." } else { Write-Log "Office C2R not found." }
})

$btnTeamsReset = New-Object System.Windows.Forms.Button; $btnTeamsReset.Text = "Nuke Teams Cache"; $btnTeamsReset.Location = New-Object System.Drawing.Point(300, 30); $btnTeamsReset.Size = New-Object System.Drawing.Size(250, 40); $btnTeamsReset.BackColor=$BtnColor; $tabOffice.Controls.Add($btnTeamsReset)
$btnTeamsReset.Add_Click({
    $path = "$env:USERPROFILE\appdata\roaming\Microsoft\Teams"
    if (Test-Path $path) { Stop-Process -Name "ms-teams", "Teams" -Force -ErrorAction SilentlyContinue; Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Teams Cache cleared." } else { Write-Log "Teams folder not found." }
})

# ==============================================================================
# TAB 4: DEBLOAT & CLEANER
# ==============================================================================
$chkXbox = New-Object System.Windows.Forms.CheckBox; $chkXbox.Text = "Xbox Apps"; $chkXbox.Location = New-Object System.Drawing.Point(30, 30); $chkXbox.AutoSize=$true; $tabDebloat.Controls.Add($chkXbox)
$chkBing = New-Object System.Windows.Forms.CheckBox; $chkBing.Text = "Bing Weather/News"; $chkBing.Location = New-Object System.Drawing.Point(30, 60); $chkBing.AutoSize=$true; $tabDebloat.Controls.Add($chkBing)
$chkZune = New-Object System.Windows.Forms.CheckBox; $chkZune.Text = "Zune Music/Video"; $chkZune.Location = New-Object System.Drawing.Point(30, 90); $chkZune.AutoSize=$true; $tabDebloat.Controls.Add($chkZune)

$btnDebloat = New-Object System.Windows.Forms.Button; $btnDebloat.Text = "REMOVE SELECTED BLOATWARE"; $btnDebloat.Location = New-Object System.Drawing.Point(20, 150); $btnDebloat.Size = New-Object System.Drawing.Size(300, 50); $btnDebloat.BackColor="#ffcccc"; $tabDebloat.Controls.Add($btnDebloat)
$btnDebloat.Add_Click({
    if ($chkXbox.Checked) { Write-Log "Removing Xbox..."; Get-AppxPackage *xbox* | Remove-AppxPackage -ErrorAction SilentlyContinue }
    if ($chkBing.Checked) { Write-Log "Removing Bing..."; Get-AppxPackage *bing* | Remove-AppxPackage -ErrorAction SilentlyContinue }
    if ($chkZune.Checked) { Write-Log "Removing Media..."; Get-AppxPackage *zune* | Remove-AppxPackage -ErrorAction SilentlyContinue }
    Write-Log "Debloat Complete."
})

$btnBrowserCache = New-Object System.Windows.Forms.Button; $btnBrowserCache.Text = "Clean All Browser Cache"; $btnBrowserCache.Location = New-Object System.Drawing.Point(350, 150); $btnBrowserCache.Size = New-Object System.Drawing.Size(250, 50); $btnBrowserCache.BackColor=$BtnColor; $tabDebloat.Controls.Add($btnBrowserCache)
$btnBrowserCache.Add_Click({
    Write-Log "Cleaning Chrome & Edge..."
    Stop-Process -Name "chrome","msedge" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Browsers Cleaned."
})

# ==============================================================================
# TAB 5: SECURITY
# ==============================================================================
$txtSec = New-Object System.Windows.Forms.RichTextBox; $txtSec.Location = New-Object System.Drawing.Point(20, 80); $txtSec.Size = New-Object System.Drawing.Size(1000, 350); $txtSec.Font = New-Object System.Drawing.Font("Consolas", 9); $tabSec.Controls.Add($txtSec)
$btnBit = New-Object System.Windows.Forms.Button; $btnBit.Text = "Check BitLocker"; $btnBit.Location = New-Object System.Drawing.Point(20, 20); $btnBit.Size = New-Object System.Drawing.Size(200, 40); $btnBit.BackColor=$BtnColor; $tabSec.Controls.Add($btnBit)
$btnBit.Add_Click({ try { $s = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop; $txtSec.Text = ($s | Out-String) } catch { $txtSec.Text = "Run as Admin." } })

# ==============================================================================
# TAB 6: PRINTERS
# ==============================================================================
$lstPrint = New-Object System.Windows.Forms.ListBox; $lstPrint.Location = New-Object System.Drawing.Point(20, 80); $lstPrint.Size = New-Object System.Drawing.Size(400, 350); $tabPrint.Controls.Add($lstPrint)
$btnScanPrint = New-Object System.Windows.Forms.Button; $btnScanPrint.Text = "Scan Printers"; $btnScanPrint.Location = New-Object System.Drawing.Point(20, 20); $btnScanPrint.Size = New-Object System.Drawing.Size(150, 40); $btnScanPrint.BackColor=$BtnColor; $tabPrint.Controls.Add($btnScanPrint)
$btnScanPrint.Add_Click({ $lstPrint.Items.Clear(); Get-Printer | ForEach-Object { $lstPrint.Items.Add($_.Name) } })
$btnSpool = New-Object System.Windows.Forms.Button; $btnSpool.Text = "Fix Spooler"; $btnSpool.Location = New-Object System.Drawing.Point(180, 20); $btnSpool.Size = New-Object System.Drawing.Size(150, 40); $btnSpool.BackColor="#ffebcd"; $tabPrint.Controls.Add($btnSpool)
$btnSpool.Add_Click({ Restart-Service Spooler -Force; Write-Log "Spooler Restarted." })

# ==============================================================================
# TAB 7: WIN UPDATE & MAINT
# ==============================================================================
$btnWinUpdFix = New-Object System.Windows.Forms.Button; $btnWinUpdFix.Text = "Fix Windows Update"; $btnWinUpdFix.Location = New-Object System.Drawing.Point(20, 30); $btnWinUpdFix.Size = New-Object System.Drawing.Size(200, 40); $btnWinUpdFix.BackColor="#ffcccc"; $tabWinUpd.Controls.Add($btnWinUpdFix)
$btnWinUpdFix.Add_Click({
    Stop-Service wuauserv -Force; Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force; Start-Service wuauserv
    Write-Log "Update Cache Cleared."
})

$btnDrv = New-Object System.Windows.Forms.Button; $btnDrv.Text = "Backup Drivers"; $btnDrv.Location = New-Object System.Drawing.Point(20, 30); $btnDrv.Size = New-Object System.Drawing.Size(200, 40); $btnDrv.BackColor=$BtnColor; $tabMaint.Controls.Add($btnDrv)
$btnDrv.Add_Click({
    $path = "$env:USERPROFILE\Desktop\DriverBackup"
    Write-Log "Backing up drivers to Desktop..."
    New-Item -Path $path -ItemType Directory -Force | Out-Null
    Export-WindowsDriver -Online -Destination $path -ErrorAction SilentlyContinue
    Write-Log "Backup Complete at: $path"
})

$btnGod = New-Object System.Windows.Forms.Button; $btnGod.Text = "Create God Mode Icon"; $btnGod.Location = New-Object System.Drawing.Point(240, 30); $btnGod.Size = New-Object System.Drawing.Size(200, 40); $btnGod.BackColor=$BtnColor; $tabMaint.Controls.Add($btnGod)
$btnGod.Add_Click({
    $godPath = "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
    New-Item -Path $godPath -ItemType Directory -Force | Out-Null
    Write-Log "God Mode created on Desktop."
})

# ==============================================================================
# TAB 8: NETWORK
# ==============================================================================
$btnPingG = New-Object System.Windows.Forms.Button; $btnPingG.Text = "Test Google"; $btnPingG.Location = New-Object System.Drawing.Point(20, 30); $btnPingG.Size = New-Object System.Drawing.Size(150, 40); $btnPingG.BackColor=$BtnColor; $tabNet.Controls.Add($btnPingG)
$btnPingG.Add_Click({ try { $p=Test-Connection google.com -Count 1 -ErrorAction Stop; Write-Log "Ping: $($p.ResponseTime)ms" } catch { Write-Log "Fail." } })

$btnFlush = New-Object System.Windows.Forms.Button; $btnFlush.Text = "Flush DNS"; $btnFlush.Location = New-Object System.Drawing.Point(180, 30); $btnFlush.Size = New-Object System.Drawing.Size(150, 40); $btnFlush.BackColor=$BtnColor; $tabNet.Controls.Add($btnFlush)
$btnFlush.Add_Click({ Start-Process cmd -ArgumentList "/c ipconfig /flushdns" -Verb RunAs -WindowStyle Hidden; Write-Log "DNS Flushed." })

# ==============================================================================
# TAB 9: APP SHOP
# ==============================================================================
if (-not (Test-Path $JsonPath)) {
    try { $AppsList = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/MertRepo/lazyadmin/main/apps.json" -ErrorAction SilentlyContinue } catch {}
} else {
    $RawJson = Get-Content $JsonPath -Raw -Encoding UTF8; $AppsList = $RawJson | ConvertFrom-Json
}
if ($AppsList) {
    $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $flowPanel.Dock = "Top"; $flowPanel.Height = 350; $flowPanel.AutoScroll = $true; $tabShop.Controls.Add($flowPanel)
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "INSTALL APPS"; $btnInstall.Location = New-Object System.Drawing.Point(20, 370); $btnInstall.Size = New-Object System.Drawing.Size(900,40); $btnInstall.BackColor="#007acc"; $btnInstall.ForeColor="White"; $tabShop.Controls.Add($btnInstall)
    
    $Categories = $AppsList | Select-Object -ExpandProperty Category -Unique
    foreach ($cat in $Categories) {
        $grp = New-Object System.Windows.Forms.GroupBox; $grp.Text = $cat; $grp.Size = New-Object System.Drawing.Size(200, 180); $grp.BackColor="White"; $flowPanel.Controls.Add($grp)
        $myApps = $AppsList | Where-Object { $_.Category -eq $cat }
        $y = 20; foreach ($app in $myApps) { $c = New-Object System.Windows.Forms.CheckBox; $c.Text=$app.Name; $c.Tag=$app.Id; $c.Location=New-Object System.Drawing.Point(10,$y); $c.AutoSize=$true; $grp.Controls.Add($c); $y+=25 }
    }
    $btnInstall.Add_Click({ 
        $appsToInstall = @(); foreach ($group in $flowPanel.Controls) { foreach ($ctrl in $group.Controls) { if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Checked) { $appsToInstall += $ctrl.Tag } } }
        foreach ($id in $appsToInstall) { Write-Log "Installing $id..."; Start-Process winget -ArgumentList "install -e --id $id --accept-package-agreements" -Wait; Write-Log "Done." }
    })
}

# ==============================================================================
# LOG BOX
# ==============================================================================
$logBox = New-Object System.Windows.Forms.RichTextBox; $logBox.Location = New-Object System.Drawing.Point(10, 540); $logBox.Size = New-Object System.Drawing.Size(1110, 180); $logBox.ReadOnly = $true; $logBox.BackColor = "Black"; $logBox.ForeColor = "#00FF00"; $logBox.Font = New-Object System.Drawing.Font("Consolas", 10); $form.Controls.Add($logBox)

Write-Log "LazyAdmin v6.0 ENTERPRISE Loaded."
Write-Log "Config Source: $SettingsPath"
$form.ShowDialog()