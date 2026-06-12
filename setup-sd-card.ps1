# DEF CON 32 Badge — SD Card Setup Script
# Run this after formatting SD card as FAT32 with 4096 byte allocation units
# Usage: .\setup-sd-card.ps1 -DriveLetter E

param(
    [Parameter(Mandatory=$true)]
    [string]$DriveLetter
)

$drive = $DriveLetter.TrimEnd(':') + ':'

# Verify drive exists
if (-not (Test-Path "$drive\")) {
    Write-Error "Drive $drive not found. Check the drive letter and try again."
    exit 1
}

# Verify FAT32 with correct cluster size
$vol = Get-WmiObject Win32_Volume | Where-Object { $_.DriveLetter -eq "$drive" }
if ($vol.FileSystem -ne "FAT32") {
    Write-Error "Drive is $($vol.FileSystem), not FAT32. Reformat with FAT32 + 4096 byte allocation units."
    exit 1
}
if ($vol.BlockSize -ne 4096) {
    Write-Warning "Cluster size is $($vol.BlockSize) bytes, should be 4096. Badge may not read the card correctly."
}

Write-Host "Setting up DEF CON 32 badge SD card on $drive..." -ForegroundColor Cyan

# Create required folders
New-Item -ItemType Directory -Force "$drive\ROM" | Out-Null
New-Item -ItemType Directory -Force "$drive\SAVE" | Out-Null
Write-Host "Created ROM/ and SAVE/ folders"

# Download v1.6 firmware
Write-Host "`nDownloading firmware v1.6..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jaku/DEFCON-32-BadgeFirmware/main/firmware/1.6/stock-firmware.bin" -OutFile "$drive\FIRMWARE.BIN" -UseBasicParsing
Write-Host "OK  FIRMWARE.BIN (flash via badge Menu -> Firmware Update)"

# ROM downloads
$roms = @(
    @{ url = "https://archive.org/download/TobuTobuGirlGame/tobu.gb"; name = "TobuTobuGirl.gb" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/ucity.gbc"; name = "uCity.gbc" },
    @{ url = "https://raw.githubusercontent.com/untoxa/BlackCastle/main/build/gb/blackcastle.gb"; name = "BlackCastle.gb" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/initiald.gbc"; name = "InitialD.gbc" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/pokedamon.gbc"; name = "Pokedamon.gbc" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/burly.gbc"; name = "Burly.gbc" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/combatsoccer.gbc"; name = "CombatSoccer.gbc" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/geometrix.gbc"; name = "Geometrix.gbc" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/klondike.gbc"; name = "Klondike.gbc" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/brickster.gbc"; name = "Brickster.gbc" },
    @{ url = "https://raw.githubusercontent.com/retrobrews/gbc-games/master/blastah.gb"; name = "Blastah.gb" },
    @{ url = "https://raw.githubusercontent.com/wyattferguson/2048-gb/master/2048.gb"; name = "2048.gb" },
    @{ url = "https://github.com/raph080/gbSnake/releases/download/v0.1/snake_v0.1.gb"; name = "Snake.gb" },
    @{ url = "https://github.com/LaroldsJubilantJunkyard/flappy-bird-gameboy/releases/download/v1.0.0/FlappyBird.gb"; name = "FlappyBird.gb" }
)

Write-Host "`nDownloading ROMs..." -ForegroundColor Cyan
foreach ($rom in $roms) {
    try {
        Invoke-WebRequest -Uri $rom.url -OutFile "$drive\ROM\$($rom.name)" -UseBasicParsing
        $size = [math]::Round((Get-Item "$drive\ROM\$($rom.name)").Length / 1KB, 1)
        Write-Host "OK  $($rom.name) ($size KB)"
    } catch {
        Write-Host "FAIL $($rom.name)" -ForegroundColor Red
    }
}

# Waternet needs zip extraction
Write-Host "Downloading Waternet (zip)..."
$tmp = "$env:TEMP\waternet.zip"
Invoke-WebRequest -Uri "https://github.com/joyrider3774/waternet/releases/download/v1.0/Waternet.Nintendo.Game.Boy.Color.zip" -OutFile $tmp -UseBasicParsing
Expand-Archive -Path $tmp -DestinationPath "$env:TEMP\waternet_extract" -Force
Get-ChildItem "$env:TEMP\waternet_extract" -Recurse | Where-Object { $_.Name -match "\.gbc$" } | Select-Object -First 1 | ForEach-Object {
    Copy-Item $_.FullName "$drive\ROM\Waternet.gbc" -Force
    Write-Host "OK  Waternet.gbc"
}
Remove-Item $tmp -Force
Remove-Item "$env:TEMP\waternet_extract" -Recurse -Force

$count = (Get-ChildItem "$drive\ROM\").Count
Write-Host "`nDone! $count ROMs loaded." -ForegroundColor Green
Write-Host "Manual downloads needed (itch.io):" -ForegroundColor Yellow
Write-Host "  Deadeus:              https://izma.itch.io/deadeus"
Write-Host "  Sheep It Up:          https://drludos.itch.io/sheep-it-up"
Write-Host "  Binding of Isaac GB:  https://jrob774.itch.io/the-binding-of-isaac-gbjam8-edition"
Write-Host "`nNext: Eject SD card, insert into badge, go to Menu -> Firmware Update -> Proceed"
