# Pet Heist 🐾

Game Roblox hoàn chỉnh thể loại **steal** — mua pet, nuôi lớn đẻ coins, trộm pet
của người khác, tát kẻ trộm, rebirth để tăng thu nhập vĩnh viễn. Toàn bộ map,
pet và gameplay dựng bằng code, không cần build tay hay asset ngoài.

> In-game text dùng tiếng Anh để tiếp cận người chơi toàn cầu.

## Cấu trúc repo

```
src/
  ReplicatedStorage/Shared/Config.lua
  ServerScriptService/
    Main.server.lua
    Game/
      Economy.lua  SaveSystem.lua  PlotManager.lua  MapBuilder.lua
      PetManager.lua  ShopSystem.lua  StealSystem.lua  RebirthSystem.lua
  StarterPlayer/StarterPlayerScripts/Client.client.lua
```

## Đưa vào Roblox Studio (khoảng 5 phút)

1. Mở **Roblox Studio** → New → **Baseplate**.
2. Tạo đúng cấu trúc sau (chuột phải → Insert Object):
   - `ReplicatedStorage` → **Folder** `Shared` → **ModuleScript** `Config`
   - `ServerScriptService` → **Folder** `Game` → 8 **ModuleScript**:
     `Economy`, `SaveSystem`, `PlotManager`, `MapBuilder`,
     `PetManager`, `ShopSystem`, `StealSystem`, `RebirthSystem`
   - `ServerScriptService` → **Script** `Main`
   - `StarterPlayer` → `StarterPlayerScripts` → **LocalScript** `Client`
3. Mở từng file `.lua` trong repo, **copy toàn bộ** paste vào Script/ModuleScript
   tương ứng trong Studio (tên file đã ghi rõ vị trí ở dòng đầu mỗi file).
4. Để test **lưu dữ liệu** trong Studio: Home → Game Settings → Security →
   bật **Enable Studio Access to API Services**.
5. Bấm **Play** để test. Mọi thứ (map, pet, shop, UI) tự dựng bằng code.
6. Hài lòng thì **File → Publish to Roblox** để lên sóng.

## Chơi thế nào

- Mở **SHOP** (góc phải) mua pet → pet tự lớn rồi đẻ coins mỗi giây
- Mua thêm chỗ khi sân đầy
- **Giữ E** gần pet người khác 3 giây để trộm (cooldown 30s)
- Trang bị **Slap** (phím 1) để tát kẻ đang trộm pet của bạn
- Đủ 1M lifetime coins → **REBIRTH** lấy +25% thu nhập vĩnh viễn

## Chỉnh sửa nhanh

Mọi thông số nằm ở `Config.lua`: giá pet, thu nhập/giây, thời gian lớn,
giá rebirth, thời gian trộm, cooldown… Sửa số rồi Play lại là xong.

## Yêu cầu

- Không cần plugin hay asset ngoài. Chạy được trên PC lẫn mobile.
- DataStore cần game đã publish (hoặc bật Studio API access khi test).
