# --- LAZYADMIN KEY GENERATOR ---
$DesktopPath = "$env:USERPROFILE\Desktop\valid_keys.json"
$Count = 100 # Kaç tane istiyorsan buraya yaz
$Prefix = "LAZY" # Anahtarın başı (Markan)

Write-Host "$Count adet anahtar üretiliyor..." -ForegroundColor Cyan

$KeyList = @()

for ($i = 0; $i -lt $Count; $i++) {
    # 3 Parçalı Rastgele Bölüm (Örn: A1B2-C9D8-E7F6)
    $Part1 = -join ((48..57) + (65..90) | Get-Random -Count 4 | ForEach-Object {[char]$_})
    $Part2 = -join ((48..57) + (65..90) | Get-Random -Count 4 | ForEach-Object {[char]$_})
    $Part3 = -join ((48..57) + (65..90) | Get-Random -Count 4 | ForEach-Object {[char]$_})
    
    # Birleştir
    $FinalKey = "$Prefix-$Part1-$Part2-$Part3"
    $KeyList += $FinalKey
}

# JSON formatına çevirip kaydet
$KeyList | ConvertTo-Json | Out-File -FilePath $DesktopPath -Encoding utf8

Write-Host "Bitti! Dosya şurada: $DesktopPath" -ForegroundColor Green
Write-Host "Bunu GitHub Gist'e yapıştırabilirsin." -ForegroundColor Yellow