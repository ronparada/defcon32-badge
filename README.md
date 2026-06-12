# DEF CON 32 Badge — Firmware Hacking & ROM Loader Setup

A walkthrough of diagnosing, fixing, and modding the DEF CON 32 (2024) badge — an RP2350-powered handheld running a bare-metal Game Boy Color emulator.

## What the Badge Is

The DC32 Human badge was designed by Mar Williams and distributed at DEF CON 32 (August 2024, Las Vegas). It runs the **Raspberry Pi RP2350** microcontroller — released to the public for the first time *at DEF CON 32*, meaning attendees had the chip before it was commercially available.

### Hardware Specs

| Component | Details |
|-----------|---------|
| MCU | Raspberry Pi RP2350 (dual ARM Cortex-M33 @ 150MHz + dual RISC-V cores) |
| RAM | 512KB on-chip (some badges have 8MB PSRAM) |
| Display | Color LCD |
| Storage | MicroSD card slot |
| LEDs | Programmable RGB LEDs |
| Wireless | IrDA infrared transceiver |
| Expansion | SAO (Simple Add-On) connector |
| Power | USB-C + rechargeable Li-ion battery |
| Audio | Speaker |
| Other | Real Time Clock, orientation sensor |

### Firmware

The badge runs **uGB** — a tiny bare-metal Game Boy Color emulator by [DmitryGR](https://dmitry.gr). It loads `.gb` and `.gbc` ROMs from a `ROM/` folder on the SD card.

---

## The Problem: Stock Firmware is Broken

The badge shipped with buggy firmware that could not properly read the SD card. Symptoms:
- `Cannot find a valid FAT filesystem on the SD card`
- Black screen when selecting a ROM
- ROM list not loading

**Root causes:**
1. Stock firmware had SD card communication bugs
2. Stock 1GB SD cards were poor quality with high failure rate
3. Windows formats SD cards with 8KB cluster size by default — badge requires 4KB

---

## Fix: Proper SD Card Format + Firmware Update

### Step 1 — Format the SD Card Correctly

The badge requires **FAT32 with 4KB (4096 byte) allocation units**. Windows default formatting uses 8KB clusters which the badge firmware rejects.

Run this in an **Administrator PowerShell**:

```powershell
"select disk X`nclean`ncreate partition primary`nselect partition 1`nformat fs=fat32 unit=4096 label=DC32BADGE quick`nassign`nexit" | diskpart
```

Replace `X` with your SD card's disk number (check with `Get-Disk` first — **do not wipe the wrong disk**).

### Step 2 — Create Required Folders

```powershell
New-Item -ItemType Directory "E:\ROM"
New-Item -ItemType Directory "E:\SAVE"
```

### Step 3 — Flash Fixed Firmware

Download the v1.6 firmware and place it on the SD card as `FIRMWARE.BIN`:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jaku/DEFCON-32-BadgeFirmware/main/firmware/1.6/stock-firmware.bin" -OutFile "E:\FIRMWARE.BIN" -UseBasicParsing
```

Then on the badge: **Menu → Firmware Update → Proceed**

It will freeze near the end — wait 15-20 seconds, then power cycle. On reboot it should show **uGB v1.6.0**.

### Firmware Versions

| Version | Notes |
|---------|-------|
| Stock (shipped) | Buggy — SD card read failures |
| v1.5 | Fixed SD card reading, downclocked SD for compatibility |
| **v1.6** | Added Rickroll IR easter egg, misc fixes — **recommended** |

Firmware source: [jaku/DEFCON-32-BadgeFirmware](https://github.com/jaku/DEFCON-32-BadgeFirmware)

---

## Loading Games

Drop any `.gb` or `.gbc` Game Boy ROM into the `ROM/` folder on the SD card. The badge supports ROMs up to 2MB.

### Homebrew ROMs (Free & Legal)

All ROMs below are freely released by their developers:

| Game | Type | Download | Description |
|------|------|----------|-------------|
| Tobu Tobu Girl | GB | [Archive.org](https://archive.org/download/TobuTobuGirlGame/tobu.gb) | Polished arcade platformer, MIT licensed |
| uCity | GBC | [retrobrews/gbc-games](https://raw.githubusercontent.com/retrobrews/gbc-games/master/ucity.gbc) | SimCity-style city builder |
| BlackCastle | GB | [untoxa/BlackCastle](https://raw.githubusercontent.com/untoxa/BlackCastle/main/build/gb/blackcastle.gb) | Action platformer |
| InitialD | GBC | [retrobrews/gbc-games](https://raw.githubusercontent.com/retrobrews/gbc-games/master/initiald.gbc) | Racing game |
| Waternet | GBC | [joyrider3774/waternet](https://github.com/joyrider3774/waternet/releases/download/v1.0/Waternet.Nintendo.Game.Boy.Color.zip) | Pipe puzzle game |
| Pokedamon | GBC | [retrobrews/gbc-games](https://raw.githubusercontent.com/retrobrews/gbc-games/master/pokedamon.gbc) | Pokemon-style RPG |
| FlappyBird | GB | [LaroldsJubilantJunkyard](https://github.com/LaroldsJubilantJunkyard/flappy-bird-gameboy/releases/download/v1.0.0/FlappyBird.gb) | Flappy Bird clone |
| 2048 | GB | [wyattferguson/2048-gb](https://raw.githubusercontent.com/wyattferguson/2048-gb/master/2048.gb) | Sliding tile puzzle |
| Snake | GB | [raph080/gbSnake](https://github.com/raph080/gbSnake/releases/download/v0.1/snake_v0.1.gb) | Classic Snake |
| Deadeus | GB | [izma.itch.io/deadeus](https://izma.itch.io/deadeus) | Horror adventure, 11 endings |
| Sheep It Up | GB | [drludos.itch.io/sheep-it-up](https://drludos.itch.io/sheep-it-up) | Arcade platformer |
| Binding of Isaac GB | GB | [jrob774.itch.io](https://jrob774.itch.io/the-binding-of-isaac-gbjam8-edition) | Roguelike demake |

### Automated Setup Script

See `setup-sd-card.ps1` to automate downloading all ROMs to a freshly formatted SD card.

---

## IR Features (v1.6)

The badge has an IrDA infrared transceiver. In v1.6 firmware:
- **Menu → Send Rickroll IR** — blasts a signal to nearby DC32 badges
- Badge-to-badge item trading in the original DC32 game

---

## Advanced / Future Options

### Doom (50fps with sound)
Graham Sanderson ported Chocolate Doom to the RP2350 specifically for this badge. Requires flashing dedicated Doom firmware (replaces GB emulator but is reversible).
- [Tom's Hardware writeup](https://www.tomshardware.com/raspberry-pi/raspberry-pi-pico/raspberry-pi-pico-2-developer-demonstrates-running-doom-on-rp2350-powered-def-con-32-badge)

### FREE-WILi Hardware Hacking Firmware
Turns the badge into a hardware multi-tool: GPIO control, I2C, IR hacking, SAO testing.
- [Hackaday writeup](https://hackaday.com/2024/11/21/free-wili-turns-dc32-badge-into-hardware-dev-tool/)

### USB Rubber Ducky Mode
Custom firmware adds Ducky Script support — badge acts as a USB HID keystroke injector.
- [morgenm/defcon32_badge_hacks](https://github.com/morgenm/defcon32_badge_hacks)

### SAO Add-ons
The SAO (Simple Add-On) connector accepts hardware expansions following the open SAO standard.

---

## Resources

- [awesome-dc32-badge](https://github.com/raulnor516/awesome-dc32-badge) — community hub for all DC32 badge mods
- [DC32 Badge Hacking Discord](https://discord.gg/z7HvmSQx) — most active community
- [DmitryGR RP2350 writeup](https://dmitry.gr/?r=06.+Thoughts&proj=11.+RP2350) — firmware author's notes
- [jaku/DEFCON-32-BadgeFirmware](https://github.com/jaku/DEFCON-32-BadgeFirmware) — firmware builds
- [defcon.org/badge/32](https://defcon.org/badge/32) — official badge page
