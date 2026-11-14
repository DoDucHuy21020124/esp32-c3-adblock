# 🛡️ C3 AdBlock — Hướng dẫn sử dụng

## Bước 1: Cắm nguồn
Cắm thiết bị vào **cổng USB** (sạc điện thoại, cục sạc, hoặc máy tính đều được).

## Bước 2: Kết nối WiFi cho thiết bị
1. Dùng **điện thoại**, vào **Settings → Wi-Fi**
2. Kết nối vào mạng **`C3-AdBlock-XXXX`** (mạng mở, không mật khẩu)
3. Trang setup **tự bật lên** (nếu không, mở trình duyệt vào `http://192.168.4.1`)
4. **Chọn WiFi nhà** từ danh sách → nhập **mật khẩu WiFi** → bấm **Connect**
5. Thiết bị tự khởi động lại và kết nối vào WiFi nhà
6. **Kết nối lại điện thoại về WiFi nhà** như bình thường

## Bước 3: Đổi DNS trên thiết bị cần chặn quảng cáo

### Trên điện thoại (Android)
Settings → Wi-Fi → giữ tên WiFi nhà → Modify → Advanced → IP settings: Static → DNS 1: nhập IP của thiết bị (xem ở bước 4) → Save

### Trên điện thoại (iPhone)
Settings → Wi-Fi → bấm (i) cạnh tên WiFi → Configure DNS → Manual → xoá DNS cũ → Add Server → nhập IP thiết bị → Save

### Trên máy tính (Windows)
Mở **PowerShell (Admin)** và chạy:
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses "<IP thiết bị>","9.9.9.9"
```

### Trên router (chặn cho cả nhà — khuyến nghị)
Vào trang quản trị router → DHCP Settings → đổi Primary DNS thành IP của thiết bị.

## Bước 4: Truy cập Dashboard
Mở trình duyệt (cùng mạng WiFi) → vào **http://c3adblock.local**
- Đăng nhập: `admin` / mật khẩu được cung cấp
- Xem số quảng cáo đã chặn, thiết bị đang dùng, thêm/xoá domain

## Đổi WiFi
- **Qua dashboard**: kéo xuống cuối → bấm **Forget WiFi** → thiết bị reboot vào chế độ setup → làm lại Bước 2
- **Bấm nút**: rút nguồn → **giữ nút BOOT** → cắm nguồn → đợi 2s → thả → làm lại Bước 2

## Gỡ bỏ / Tắt chặn
- **Tạm dừng**: Dashboard → bấm **Pause** → chọn thời gian
- **Tắt hẳn**: đổi DNS về tự động:
  ```powershell
  Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ResetServerAddresses
  ```
  hoặc trên điện thoại đổi DNS về Automatic
