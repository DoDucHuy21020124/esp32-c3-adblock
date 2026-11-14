# flash.ps1 — Build và nạp firmware + blocklist cho ESP32-C3 AdBlock
#
# Cách chạy (từ thư mục này):
#   powershell -ExecutionPolicy Bypass -File .\flash.ps1
#
# Tuỳ chọn:
#   -Port COM5           đổi cổng COM (mặc định COM7)
#   -RebuildBlocklist    tải lại blocklist mới nhất dù đã có data\blocklist.bin
#   -SkipFs              không nạp blocklist (giữ nguyên tên miền tự thêm / danh sách ban trên thiết bị)
#   -NoMonitor           không mở cửa sổ log sau khi nạp
#   -EraseAll            xoá SẠCH chip trước khi nạp (WiFi đã lưu, tên miền tự thêm, danh sách ban...)
#                        → dùng trước khi giao thiết bị cho người khác

param(
    [string]$Port = "COM7",
    [switch]$RebuildBlocklist,
    [switch]$SkipFs,
    [switch]$NoMonitor,
    [switch]$EraseAll
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8   # hiển thị đúng tiếng Việt có dấu
Set-Location -Path $PSScriptRoot

$pio = Join-Path $env:USERPROFILE ".platformio\penv\Scripts\pio.exe"
$py  = Join-Path $env:USERPROFILE ".platformio\penv\Scripts\python.exe"

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Fail($msg) { Write-Host "`n[LỖI] $msg" -ForegroundColor Red; exit 1 }
function Run($exe, [string[]]$argv) {
    & $exe @argv
    if ($LASTEXITCODE -ne 0) { Fail "Lệnh thất bại (mã lỗi $LASTEXITCODE): $exe $($argv -join ' ')" }
}

# ---- 1. Kiểm tra môi trường ----
Step "Kiểm tra PlatformIO"
if (-not (Test-Path $pio)) { Fail "Không tìm thấy PlatformIO tại $pio. Hãy cài extension PlatformIO IDE trong VS Code trước." }
if (-not (Test-Path $py))  { Fail "Không tìm thấy Python của PlatformIO tại $py." }
Write-Host "OK: $pio"

# ---- 2. Kiểm tra secrets.h ----
Step "Kiểm tra src\secrets.h"
$secrets = "src\secrets.h"
if (-not (Test-Path $secrets)) { Fail "Chưa có $secrets. Chạy: copy src\secrets.example.h src\secrets.h rồi đặt mật khẩu." }
$txt = Get-Content $secrets -Raw

$weak = @()
foreach ($name in "WEB_PASS", "OTA_PASS") {
    $m = [regex]::Match($txt, $name + '\s*=\s*"([^"]*)"')
    if (-not $m.Success) { Fail "Không đọc được $name trong secrets.h." }
    if ($m.Groups[1].Value -like "CHANGE_ME_*") { Fail "$name vẫn là mật khẩu mặc định CHANGE_ME_... → hãy đổi trong secrets.h." }
    if ($m.Groups[1].Value.Length -lt 12) { $weak += $name }
}
if ($weak.Count -gt 0) {
    Write-Host "[CẢNH BÁO] $($weak -join ', ') ngắn hơn 12 ký tự — người trong mạng WiFi có thể dò ra và nạp firmware độc." -ForegroundColor Yellow
    $ans = Read-Host "Vẫn tiếp tục nạp? (y/N)"
    if ($ans -notmatch '^[yY]') { Write-Host "Đã huỷ. Sửa secrets.h rồi chạy lại."; exit 0 }
} else {
    Write-Host "OK: mật khẩu đủ dài"
}
if ($txt -notmatch 'WIFI_SSID\s*=\s*"YOUR_WIFI_SSID"') {
    Write-Host "[LƯU Ý] secrets.h có sẵn WiFi → thiết bị sẽ tự vào mạng đó. Nếu giao cho người khác, nên để lại YOUR_WIFI_SSID." -ForegroundColor Yellow
}
if ($EraseAll -and $SkipFs) { Fail "-EraseAll xoá cả blocklist, không dùng chung với -SkipFs được." }

# ---- 3. Blocklist ----
$bl = "data\blocklist.bin"
if (-not $SkipFs) {
    if ($RebuildBlocklist -or -not (Test-Path $bl)) {
        Step "Tạo blocklist (tải từ StevenBlack + Hagezi)"
        Run $py @("tools\build_blocklist.py", $bl)
    } else {
        Step "Dùng blocklist có sẵn: $bl ($([math]::Round((Get-Item $bl).Length / 1KB)) KB) — thêm -RebuildBlocklist để tải mới"
    }
}

# ---- 4. Build + nạp firmware ----
if ($EraseAll) {
    Step "Xoá sạch chip (WiFi đã lưu, cấu hình, blocklist cũ)"
    Run $pio @("run", "-e", "c3", "-t", "erase", "--upload-port", $Port)
}
Step "Build và nạp firmware qua $Port"
Write-Host "Lần đầu sẽ lâu (5–15 phút) vì phải tải bộ công cụ ESP32." -ForegroundColor DarkGray
Write-Host "Nếu báo 'Failed to connect': rút USB, nối chân GPIO9 với GND, cắm lại USB, bỏ dây ra rồi chạy lại." -ForegroundColor DarkGray
Run $pio @("run", "-e", "c3", "-t", "upload", "--upload-port", $Port)

# ---- 5. Nạp blocklist (LittleFS) ----
if (-not $SkipFs) {
    Step "Nạp blocklist vào bộ nhớ flash (ghi đè toàn bộ LittleFS)"
    Run $pio @("run", "-e", "c3", "-t", "uploadfs", "--upload-port", $Port)
}

Write-Host "`n[XONG] Đã nạp firmware thành công." -ForegroundColor Green
Write-Host "Lần đầu sử dụng: dùng điện thoại kết nối WiFi 'C3-AdBlock-XXXX', chọn WiFi nhà và nhập mật khẩu."
Write-Host "Sau đó mở http://c3adblock.local (đăng nhập: admin + WEB_PASS)."
Write-Host "Lần sau có thể nạp firmware qua mạng: dashboard → FIRMWARE → chọn .pio\build\c3\firmware.bin."

# ---- 6. Cửa sổ log ----
if (-not $NoMonitor) {
    Step "Mở cửa sổ log (Ctrl+C để thoát)"
    & $pio device monitor -p $Port -b 115200
}
