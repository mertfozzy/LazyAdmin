Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Linq

# --- CONFIGURATION ---
$ScriptPath = $PSScriptRoot
# Eğer Cloud kullanıyorsan URL'yi buraya yazarsın, yoksa yerel dosya:
$JsonPath = "$ScriptPath\apps.json"

# --- MAIN FORM SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "LazyAdmin v5.0 (Ultimate Edition)"
$form.Size = New-Object System.Drawing.Size(1100, 750) # Biraz daha genişlettik
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
$tabControl.Size = New-Object System.Drawing.Size(1060, 500)
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$tabControl.SizeMode = "FillToRight"
$form.Controls.Add($tabControl)

# Sekmeler
$tabDash   = New-Object System.Windows.Forms.TabPage; $tabDash.Text   = "Dashboard"
$tabOffice = New-Object System.Windows.Forms.TabPage; $tabOffice.Text = "Office 365"
$tabSec    = New-Object System.Windows.Forms.TabPage; $tabSec.Text    = "Security"
$tabPrint  = New-Object System.Windows.Forms.TabPage; $tabPrint.Text  = "Printers"
$tabLogs   = New-Object System.Windows.Forms.TabPage; $tabLogs.Text   = "Deep Logs"
$tabRemote = New-Object System.Windows.Forms.TabPage; $tabRemote.Text = "Remote"
$tabWinUpd = New-Object System.Windows.Forms.TabPage; $tabWinUpd.Text = "Win Update" # YENİ
$tabBrows  = New-Object System.Windows.Forms.TabPage; $tabBrows.Text  = "Browsers"   # YENİ
$tabMaint  = New-Object System.Windows.Forms.TabPage; $tabMaint.Text  = "Maint."
$tabNet    = New-Object System.Windows.Forms.TabPage; $tabNet.Text    = "Network"
$tabShop   = New-Object System.Windows.Forms.TabPage; $tabShop.Text   = "App Shop"

$tabControl.Controls.Add($tabDash)
$tabControl.Controls.Add($tabOffice)
$tabControl.Controls.Add($tabSec)
$tabControl.Controls.Add($tabPrint)
$tabControl.Controls.Add($tabLogs)
$tabControl.Controls.Add($tabRemote)
$tabControl.Controls.Add($tabWinUpd)
$tabControl.Controls.Add($tabBrows)
$tabControl.Controls.Add($tabMaint)
$tabControl.Controls.Add($tabNet)
$tabControl.Controls.Add($tabShop)

# ==============================================================================
# TAB 1: DASHBOARD (Updated with Serial & Public IP) 📊
# ==============================================================================
$grpInfo = New-Object System.Windows.Forms.GroupBox; $grpInfo.Text = "System Overview"; $grpInfo.Location = New-Object System.Drawing.Point(10, 10); $grpInfo.Size = New-Object System.Drawing.Size(1030, 440); $tabDash.Controls.Add($grpInfo)
$lblInfo = New-Object System.Windows.Forms.Label; $lblInfo.Location = New-Object System.Drawing.Point(20, 30); $lblInfo.Size = New-Object System.Drawing.Size(990, 400); $lblInfo.Font = New-Object System.Drawing.Font("Consolas", 10); $grpInfo.Controls.Add($lblInfo)

function Refresh-Dashboard {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $bios = Get-CimInstance Win32_BIOS
        $disk = Get-Volume -DriveLetter C
        $freeSpace = [math]::Round($disk.SizeRemaining / 1GB, 1)
        $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $uptime = (Get-Date) - $os.LastBootUpTime
        
        # Public IP çekme (Hızlıca)
        try { $pubIP = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 2 } catch { $pubIP = "Offline" }

        $infoText = "Computer Name : $($env:COMPUTERNAME) `nUser          : $($env:USERNAME) `nSerial No     : $($bios.SerialNumber) (Asset ID) `nOS Version    : $($os.Caption) `nPublic IP     : $pubIP `n`nFree Disk (C:): $freeSpace GB `nTotal RAM     : $totalRam GB `nSystem Uptime : $([math]::Round($uptime.TotalHours, 1)) Hours `n`n--- Disk Health ---`n"
        $phyDisks = Get-CimInstance -Namespace root\Microsoft\Windows\Storage -ClassName MSFT_PhysicalDisk
        foreach ($d in $phyDisks) { $infoText += "Disk: $($d.FriendlyName) | Status: $($d.HealthStatus) `n" }
        $lblInfo.Text = $infoText
    } catch { $lblInfo.Text = "Error fetching info." }
}
Refresh-Dashboard

# ==============================================================================
# TAB 2: OFFICE & 365 DOCTOR
# ==============================================================================
$btnOutReset = New-Object System.Windows.Forms.Button; $btnOutReset.Text = "Reset Outlook Profile (Reg)"; $btnOutReset.Location = New-Object System.Drawing.Point(20, 30); $btnOutReset.Size = New-Object System.Drawing.Size(250, 40); $btnOutReset.BackColor="#ffcccc"; $tabOffice.Controls.Add($btnOutReset)
$btnOutReset.Add_Click({
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\Outlook"
    if (-not (Test-Path $regPath)) { [System.Windows.Forms.MessageBox]::Show("Outlook Profile not found.", "Error", 0, 16); return }
    if ([System.Windows.Forms.MessageBox]::Show("Delete Outlook Profile?", "Warning", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning) -eq 'Yes') {
        Stop-Process -Name "OUTLOOK" -Force -ErrorAction SilentlyContinue
        Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Profile reset."
    }
})

$btnOffRep = New-Object System.Windows.Forms.Button; $btnOffRep.Text = "Run Office Quick Repair"; $btnOffRep.Location = New-Object System.Drawing.Point(20, 80); $btnOffRep.Size = New-Object System.Drawing.Size(250, 40); $btnOffRep.BackColor="White"; $tabOffice.Controls.Add($btnOffRep)
$btnOffRep.Add_Click({
    $officeClickToRun = "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"
    if (Test-Path $officeClickToRun) { Start-Process $officeClickToRun -ArgumentList "scenario=Repair", "platform=x64", "culture=en-us", "RepairType=QuickRepair", "DisplayLevel=True"; Write-Log "Repair launched." } else { Write-Log "Office C2R not found." }
})

$btnTeamsReset = New-Object System.Windows.Forms.Button; $btnTeamsReset.Text = "Nuke Teams Cache"; $btnTeamsReset.Location = New-Object System.Drawing.Point(300, 30); $btnTeamsReset.Size = New-Object System.Drawing.Size(250, 40); $btnTeamsReset.BackColor="White"; $tabOffice.Controls.Add($btnTeamsReset)
$btnTeamsReset.Add_Click({
    $path = "$env:USERPROFILE\appdata\roaming\Microsoft\Teams"
    if (Test-Path $path) { Stop-Process -Name "ms-teams", "Teams" -Force -ErrorAction SilentlyContinue; Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Teams Cache cleared." } else { Write-Log "Teams folder not found." }
})

# ==============================================================================
# TAB 3: SECURITY & AUDIT
# ==============================================================================
$txtSec = New-Object System.Windows.Forms.RichTextBox; $txtSec.Location = New-Object System.Drawing.Point(20, 80); $txtSec.Size = New-Object System.Drawing.Size(1000, 350); $txtSec.Font = New-Object System.Drawing.Font("Consolas", 9); $tabSec.Controls.Add($txtSec)

$btnBit = New-Object System.Windows.Forms.Button; $btnBit.Text = "Check BitLocker"; $btnBit.Location = New-Object System.Drawing.Point(20, 20); $btnBit.Size = New-Object System.Drawing.Size(200, 40); $btnBit.BackColor="White"; $tabSec.Controls.Add($btnBit)
$btnBit.Add_Click({ try { $status = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop | Select-Object MountPoint, ProtectionStatus, EncryptionPercentage, VolumeStatus; $txtSec.Text = ($status | Out-String) } catch { $txtSec.Text = "Access Denied (Run as Admin)." } })

$btnAdm = New-Object System.Windows.Forms.Button; $btnAdm.Text = "List Local Admins"; $btnAdm.Location = New-Object System.Drawing.Point(230, 20); $btnAdm.Size = New-Object System.Drawing.Size(200, 40); $btnAdm.BackColor="White"; $tabSec.Controls.Add($btnAdm)
$btnAdm.Add_Click({ try { $members = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop; $txtSec.Text = "--- LOCAL ADMINISTRATORS ---`n" + ($members | Out-String) } catch { $txtSec.Text = "Access Denied." } })

# ==============================================================================
# TAB 4: PRINTERS
# ==============================================================================
$lstPrint = New-Object System.Windows.Forms.ListBox; $lstPrint.Location = New-Object System.Drawing.Point(20, 80); $lstPrint.Size = New-Object System.Drawing.Size(400, 350); $tabPrint.Controls.Add($lstPrint)
$btnScanPrint = New-Object System.Windows.Forms.Button; $btnScanPrint.Text = "Scan Printers"; $btnScanPrint.Location = New-Object System.Drawing.Point(20, 20); $btnScanPrint.Size = New-Object System.Drawing.Size(150, 40); $btnScanPrint.BackColor="White"; $tabPrint.Controls.Add($btnScanPrint)
$btnScanPrint.Add_Click({ $lstPrint.Items.Clear(); Get-Printer | ForEach-Object { $lstPrint.Items.Add($_.Name) } })

$btnResetSpool = New-Object System.Windows.Forms.Button; $btnResetSpool.Text = "Restart Spooler"; $btnResetSpool.Location = New-Object System.Drawing.Point(180, 20); $btnResetSpool.Size = New-Object System.Drawing.Size(200, 40); $btnResetSpool.BackColor="#ffebcd"; $tabPrint.Controls.Add($btnResetSpool)
$btnResetSpool.Add_Click({ Restart-Service Spooler -Force -ErrorAction SilentlyContinue; Write-Log "Spooler restarted." })

$btnTestPage = New-Object System.Windows.Forms.Button; $btnTestPage.Text = "Print Test Page"; $btnTestPage.Location = New-Object System.Drawing.Point(440, 80); $btnTestPage.Size = New-Object System.Drawing.Size(200, 40); $btnTestPage.BackColor="White"; $tabPrint.Controls.Add($btnTestPage)
$btnTestPage.Add_Click({ if ($lstPrint.SelectedItem) { try { (Get-WmiObject Win32_Printer -Filter "Name='$($lstPrint.SelectedItem)'").PrintTestPage() | Out-Null; Write-Log "Sent." } catch { Write-Log "Error." } } })

# ==============================================================================
# TAB 5: DEEP LOGS
# ==============================================================================
$txtLogs = New-Object System.Windows.Forms.RichTextBox; $txtLogs.Location = New-Object System.Drawing.Point(20, 80); $txtLogs.Size = New-Object System.Drawing.Size(1000, 350); $txtLogs.Font = New-Object System.Drawing.Font("Consolas", 9); $txtLogs.BackColor="Black"; $txtLogs.ForeColor="#00ff00"; $tabLogs.Controls.Add($txtLogs)
$btnBsod = New-Object System.Windows.Forms.Button; $btnBsod.Text = "Check Critical Errors"; $btnBsod.Location = New-Object System.Drawing.Point(20, 20); $btnBsod.Size = New-Object System.Drawing.Size(200, 40); $btnBsod.BackColor="White"; $tabLogs.Controls.Add($btnBsod)
$btnBsod.Add_Click({ $errs = Get-EventLog -LogName System -EntryType Error,Warning -Newest 10 -ErrorAction SilentlyContinue | Where-Object { $_.EventID -eq 41 -or $_.EventID -eq 6008 }; $txtLogs.Text = if ($errs) { $errs | Out-String } else { "No critical errors found." } })

# ==============================================================================
# TAB 6: REMOTE TOOLS
# ==============================================================================
$lblTarget = New-Object System.Windows.Forms.Label; $lblTarget.Text = "Target IP:"; $lblTarget.Location = New-Object System.Drawing.Point(20, 30); $lblTarget.AutoSize=$true; $tabRemote.Controls.Add($lblTarget)
$txtTarget = New-Object System.Windows.Forms.TextBox; $txtTarget.Location = New-Object System.Drawing.Point(100, 27); $txtTarget.Size = New-Object System.Drawing.Size(200, 20); $tabRemote.Controls.Add($txtTarget)

$btnRDP = New-Object System.Windows.Forms.Button; $btnRDP.Text = "Launch RDP"; $btnRDP.Location = New-Object System.Drawing.Point(20, 70); $btnRDP.Size = New-Object System.Drawing.Size(120, 40); $btnRDP.BackColor="White"; $tabRemote.Controls.Add($btnRDP)
$btnRDP.Add_Click({ if ($txtTarget.Text) { Start-Process "mstsc.exe" -ArgumentList "/v:$($txtTarget.Text)" } })

$btnCShare = New-Object System.Windows.Forms.Button; $btnCShare.Text = "Open C$"; $btnCShare.Location = New-Object System.Drawing.Point(150, 70); $btnCShare.Size = New-Object System.Drawing.Size(120, 40); $btnCShare.BackColor="White"; $tabRemote.Controls.Add($btnCShare)
$btnCShare.Add_Click({ if ($txtTarget.Text) { Invoke-Item "\\$($txtTarget.Text)\c$" } })

# ==============================================================================
# TAB 7: WINDOWS UPDATE (NEW!) 🔄
# ==============================================================================
$btnFixUpd = New-Object System.Windows.Forms.Button; $btnFixUpd.Text = "⚠️ Fix WinUpdate (Clear Cache)"; $btnFixUpd.Location = New-Object System.Drawing.Point(20, 30); $btnFixUpd.Size = New-Object System.Drawing.Size(300, 40); $btnFixUpd.BackColor="#ffcccc"; $tabWinUpd.Controls.Add($btnFixUpd)
$btnFixUpd.Add_Click({
    Write-Log "Stopping Windows Update Service..."
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue
    Write-Log "Clearing SoftwareDistribution..."
    Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Starting Services..."
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Write-Log "Done. Try checking updates again."
})

$btnCheckUpd = New-Object System.Windows.Forms.Button; $btnCheckUpd.Text = "Open WU Settings"; $btnCheckUpd.Location = New-Object System.Drawing.Point(20, 80); $btnCheckUpd.Size = New-Object System.Drawing.Size(300, 40); $btnCheckUpd.BackColor="White"; $tabWinUpd.Controls.Add($btnCheckUpd)
$btnCheckUpd.Add_Click({ Start-Process "ms-settings:windowsupdate" })

# ==============================================================================
# TAB 8: BROWSER CARE (NEW!) 🌐
# ==============================================================================
$btnCleanChrome = New-Object System.Windows.Forms.Button; $btnCleanChrome.Text = "Clear Chrome Cache"; $btnCleanChrome.Location = New-Object System.Drawing.Point(20, 30); $btnCleanChrome.Size = New-Object System.Drawing.Size(250, 40); $btnCleanChrome.BackColor="White"; $tabBrows.Controls.Add($btnCleanChrome)
$btnCleanChrome.Add_Click({
    Write-Log "Killing Chrome..."
    Stop-Process -Name "chrome" -Force -ErrorAction SilentlyContinue
    $cPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*"
    if (Test-Path $cPath) { Remove-Item $cPath -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Chrome Cache Cleared." } else { Write-Log "Chrome not found." }
})

$btnCleanEdge = New-Object System.Windows.Forms.Button; $btnCleanEdge.Text = "Clear Edge Cache"; $btnCleanEdge.Location = New-Object System.Drawing.Point(280, 30); $btnCleanEdge.Size = New-Object System.Drawing.Size(250, 40); $btnCleanEdge.BackColor="White"; $tabBrows.Controls.Add($btnCleanEdge)
$btnCleanEdge.Add_Click({
    Write-Log "Killing Edge..."
    Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
    $ePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*"
    if (Test-Path $ePath) { Remove-Item $ePath -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Edge Cache Cleared." } else { Write-Log "Edge not found." }
})

# ==============================================================================
# TAB 9: MAINTENANCE
# ==============================================================================
$btnTemp = New-Object System.Windows.Forms.Button; $btnTemp.Text = "Clean Temp Files"; $btnTemp.Location = New-Object System.Drawing.Point(20, 30); $btnTemp.Size = New-Object System.Drawing.Size(200, 40); $btnTemp.BackColor="White"; $tabMaint.Controls.Add($btnTemp)
$btnTemp.Add_Click({ Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Temp cleaned." })

$btnSFC = New-Object System.Windows.Forms.Button; $btnSFC.Text = "Run SFC Scannow"; $btnSFC.Location = New-Object System.Drawing.Point(240, 30); $btnSFC.Size = New-Object System.Drawing.Size(200, 40); $btnSFC.BackColor="#fff3cd"; $tabMaint.Controls.Add($btnSFC)
$btnSFC.Add_Click({ Start-Process powershell -ArgumentList "-NoExit", "-Command", "sfc /scannow" -Verb RunAs })

$btnBattery = New-Object System.Windows.Forms.Button; $btnBattery.Text = "Battery Report"; $btnBattery.Location = New-Object System.Drawing.Point(20, 80); $btnBattery.Size = New-Object System.Drawing.Size(200, 40); $btnBattery.BackColor="White"; $tabMaint.Controls.Add($btnBattery)
$btnBattery.Add_Click({ powercfg /batteryreport /output "$env:USERPROFILE\Desktop\battery_report.html"; Write-Log "Report saved to Desktop." })

$btnHighPerf = New-Object System.Windows.Forms.Button; $btnHighPerf.Text = "Force High Performance"; $btnHighPerf.Location = New-Object System.Drawing.Point(240, 80); $btnHighPerf.Size = New-Object System.Drawing.Size(200, 40); $btnHighPerf.BackColor="White"; $tabMaint.Controls.Add($btnHighPerf)
$btnHighPerf.Add_Click({ powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c; Write-Log "Power Mode: High Performance" })

# ==============================================================================
# TAB 10: NETWORK
# ==============================================================================
$btnPingG = New-Object System.Windows.Forms.Button; $btnPingG.Text = "Test Google"; $btnPingG.Location = New-Object System.Drawing.Point(20, 30); $btnPingG.Size = New-Object System.Drawing.Size(150, 40); $btnPingG.BackColor="White"; $tabNet.Controls.Add($btnPingG)
$btnPingG.Add_Click({ try { $p=Test-Connection google.com -Count 1 -ErrorAction Stop; Write-Log "Ping: $($p.ResponseTime)ms" } catch { Write-Log "Fail." } })

$btnFlush = New-Object System.Windows.Forms.Button; $btnFlush.Text = "Flush DNS"; $btnFlush.Location = New-Object System.Drawing.Point(180, 30); $btnFlush.Size = New-Object System.Drawing.Size(150, 40); $btnFlush.BackColor="White"; $tabNet.Controls.Add($btnFlush)
$btnFlush.Add_Click({ Start-Process cmd -ArgumentList "/c ipconfig /flushdns" -Verb RunAs -WindowStyle Hidden; Write-Log "DNS Flushed." })

# Port Tester
$lblPort = New-Object System.Windows.Forms.Label; $lblPort.Text = "Port Test (IP:Port):"; $lblPort.Location = New-Object System.Drawing.Point(350, 35); $lblPort.AutoSize=$true; $tabNet.Controls.Add($lblPort)
$txtPort = New-Object System.Windows.Forms.TextBox; $txtPort.Location = New-Object System.Drawing.Point(470, 32); $txtPort.Size = New-Object System.Drawing.Size(150, 20); $txtPort.Text="google.com:443"; $tabNet.Controls.Add($txtPort)
$btnPort = New-Object System.Windows.Forms.Button; $btnPort.Text = "Test"; $btnPort.Location = New-Object System.Drawing.Point(630, 30); $btnPort.Size = New-Object System.Drawing.Size(80, 25); $btnPort.BackColor="White"; $tabNet.Controls.Add($btnPort)
$btnPort.Add_Click({
    $pArr = $txtPort.Text.Split(":")
    if ($pArr.Count -eq 2) {
        try { $t = Test-NetConnection -ComputerName $pArr[0] -Port $pArr[1] -WarningAction SilentlyContinue; if ($t.TcpTestSucceeded) { Write-Log "Port Open!" } else { Write-Log "Port CLOSED." } } catch { Write-Log "Error." }
    } else { Write-Log "Format: IP:Port" }
})

# ==============================================================================
# TAB 11: APP SHOP
# ==============================================================================
if (-not (Test-Path $JsonPath)) {
    try { $AppsList = Invoke-RestMethod -Uri $JsonPath -ErrorAction Stop } catch { 
        $lblErr = New-Object System.Windows.Forms.Label; $lblErr.Text = "apps.json not found (Local or Cloud)!"; $lblErr.ForeColor="Red"; $lblErr.Location = New-Object System.Drawing.Point(20,20); $lblErr.AutoSize=$true; $tabShop.Controls.Add($lblErr) 
    }
} else {
    $RawJson = Get-Content $JsonPath -Raw -Encoding UTF8; $AppsList = $RawJson | ConvertFrom-Json
}

if ($AppsList) {
    $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel; $flowPanel.Dock = "Top"; $flowPanel.Height = 350; $flowPanel.AutoScroll = $true; $flowPanel.FlowDirection = "LeftToRight"; $flowPanel.WrapContents = $true; $tabShop.Controls.Add($flowPanel)
    $Categories = $AppsList | Select-Object -ExpandProperty Category -Unique
    foreach ($cat in $Categories) {
        $grp = New-Object System.Windows.Forms.GroupBox; $grp.Text = $cat; $grp.Size = New-Object System.Drawing.Size(220, 200); $grp.Margin = New-Object System.Windows.Forms.Padding(10); $grp.BackColor = "White"
        $myApps = $AppsList | Where-Object { $_.Category -eq $cat }
        $yPos = 20
        foreach ($app in $myApps) { $chk = New-Object System.Windows.Forms.CheckBox; $chk.Text = $app.Name; $chk.Tag = $app.Id; $chk.Location = New-Object System.Drawing.Point(10, $yPos); $chk.AutoSize = $true; $grp.Controls.Add($chk); $yPos += 25 }
        $flowPanel.Controls.Add($grp)
    }
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "INSTALL SELECTED APPS"; $btnInstall.Size = New-Object System.Drawing.Size(900, 40); $btnInstall.Location = New-Object System.Drawing.Point(20, 360); $btnInstall.BackColor = "#007acc"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"
    $btnInstall.Add_Click({
        $appsToInstall = @(); foreach ($group in $flowPanel.Controls) { foreach ($ctrl in $group.Controls) { if ($ctrl -is [System.Windows.Forms.CheckBox] -and $ctrl.Checked) { $appsToInstall += $ctrl.Tag } } }
        if ($appsToInstall.Count -eq 0) { Write-Log "No apps selected."; return }
        foreach ($appID in $appsToInstall) { Write-Log "Installing $appID..."; Start-Process winget -ArgumentList "install -e --id $appID --accept-package-agreements" -Wait; Write-Log "$appID Done." }
    })
    $tabShop.Controls.Add($btnInstall)
}

# ==============================================================================
# LOG BOX
# ==============================================================================
$logBox = New-Object System.Windows.Forms.RichTextBox; $logBox.Location = New-Object System.Drawing.Point(10, 520); $logBox.Size = New-Object System.Drawing.Size(1060, 180); $logBox.ReadOnly = $true; $logBox.BackColor = "Black"; $logBox.ForeColor = "#00FF00"; $logBox.Font = New-Object System.Drawing.Font("Consolas", 10); $form.Controls.Add($logBox)

# --- START ---
Write-Log "LazyAdmin v5.0 ULTIMATE Edition Initialized..."
$form.ShowDialog()