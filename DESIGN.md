# Pet Heist — Game Design Document

## 1. Đánh giá thể loại (dữ liệu tháng 11/2026)

| Thể loại | Đại diện hot | Số liệu | Độ hút | Độ khó làm (solo dev, code thuần) | Nhận xét |
|---|---|---|---|---|---|
| **Steal / Heist** | Steal An Egg (~1.27M CCU, 9.6B visits từ 7/2026), Steal a Brainrot (18.5B visits H1/2026) | Đương kim số 1 Roblox | ⭐⭐⭐⭐⭐ | Thấp — loop đơn giản, dựng map bằng code | **CHỌN.** Công thức viral mạnh nhất 2025–2026: thu thập + trộm lẫn nhau + drama xã hội = content tự lan trên TikTok/YouTube |
| Pet sim | Adopt Me! (43.2B visits), Pet Simulator 99 | Rất cao | ⭐⭐⭐⭐⭐ | Trung bình | Pet là "nam châm" hút người chơi nhí số 1 Roblox → **kết hợp pet + steal** |
| Garden / Idle sim | Grow a Garden 2 (~454K CCU) | Rất cao | ⭐⭐⭐⭐ | Thấp | Đã bị 2 ông lớn chiếm lĩnh |
| Obby | Tower of Hell | Trung bình–cao | ⭐⭐⭐ | Trung bình | Khó nổi bật nếu không có twist mạnh |
| Horror (Doors-like) | DOORS | Cao | ⭐⭐⭐⭐ | Cao — cần art, âm thanh | Không phù hợp làm bằng code thuần |
| Tycoon cổ điển | — | Trung bình | ⭐⭐ | Thấp | Bão hòa |

**Kết luận:** Kết hợp 2 xu hướng mạnh nhất — **steal** (công thức viral #1) +
**pet** (chủ đề hút người chơi nhất, đặc biệt lứa tuổi nhỏ). Pet được dựng từ
các khối Part trong code, không cần asset ngoài.

## 2. Concept: Pet Heist

Mỗi người chơi có một **sân (yard)**. Mua **pet** đặt vào sân → pet lớn dần theo
thời gian → pet đẻ **coins** mỗi giây. Pet càng hiếm, đẻ càng nhiều.

Điểm gây nghiện: **giữ E gần pet của người khác 3 giây để trộm** — pet bị trộm
chạy sang sân của mình. Chủ pet nhận cảnh báo và có thể dùng **Slap** (tát) để
ngắt vụ trộm giữa chừng + hất văng kẻ trộm.

## 3. Core loop

```
Mua pet → Đặt vào sân → Pet lớn dần → Đẻ coins/giây
   → Mua pet hiếm hơn / mở thêm chỗ
   → TRỘM pet người khác để nhảy cóc
   → Rebirth: reset lấy +25% thu nhập vĩnh viễn (cộng dồn)
```

## 4. Hệ thống

- **Pet 6 bậc:** Tabby Cat → Puppy → Fox → Dragon → Phoenix → Golden Unicorn
  (giá 50 → 250K coins, thu nhập 2 → 1800 coins/s, thời gian lớn 20s → 120s)
- **Sân:** 12 plot xếp vòng tròn, mỗi người 3–8 chỗ (mua thêm chỗ bằng coins)
- **Trộm:** giữ E 3s, cooldown 30s, nạn nhân được báo động
- **Slap:** tool ai cũng có — tát gây 10 dmg + hất văng + ngắt vụ trộm đang diễn ra
- **Rebirth:** cần 1M lifetime coins → +25% thu nhập vĩnh viễn mỗi lần
- **Lưu trữ:** DataStore (coins, pet + độ trưởng thành, rebirth, số chỗ), autosave 120s
- **Bảng xếp hạng:** leaderstats Coins mặc định của Roblox
- **Map & pet:** dựng 100% bằng code — sân, shop, 12 plot, cây trang trí, điểm spawn,
  pet lắp từ các khối (thân, đầu, tai, mắt, đuôi, chân)

## 5. Cân bằng (tuning)

- Người chơi mới (100 coins khởi đầu) mua được 1 Tabby Cat (50c) sau ~10 giây
- Cat hồi vốn sau 25s đẻ → nhịp "mua → lời → mua tiếp" nhanh, gây nghiện sớm
- Trộm là shortcut: 1 con Phoenix trộm được = tiết kiệm ~45K coins cày
- Rebirth đầu tiên khả thi sau ~15–25 phút chơi tích cực → giữ chân dài hạn

## 6. Hướng phát triển tiếp (sau bản 1.0)

- Pet sự kiện giới hạn giờ, pet chỉ rơi từ rebirth
- Hệ thống trade giữa người chơi
- Gamepass: x2 income, slap mạnh hơn, thêm chỗ
- Pet hoang giữa map: ai giữ E đủ lâu thì cả server tranh nhau
