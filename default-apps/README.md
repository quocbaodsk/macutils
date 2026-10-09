# default-apps

> Thuộc repo [macutils](../README.md).

Bộ script Swift nhỏ để **xem** và **đặt** app mặc định mở các loại file trên macOS
(thay cho thao tác *Get Info → Open with → Change All…* lặp đi lặp lại trong Finder).

| Script | Việc làm | Thay đổi hệ thống? |
| --- | --- | --- |
| `preview.swift` | Xem app mặc định + mọi app có thể mở cho từng đuôi file | ❌ Chỉ đọc |
| `setdefault.swift` | Đặt một app làm mặc định cho nhiều đuôi file cùng lúc | ✅ Có (macOS hỏi xác nhận) |

Danh sách đuôi mặc định (dùng khi không truyền đuôi nào):

```
json, md, php, js, ts, xml, yaml, yml, sql
```

---

## Yêu cầu

- macOS 12 (Monterey) trở lên — cần `UniformTypeIdentifiers` và API
  `NSWorkspace.setDefaultApplication(at:toOpen:)`.
- Swift toolchain: cài **Xcode** hoặc **Command Line Tools**:

  ```sh
  xcode-select --install
  swift --version
  ```

Không có dependency bên ngoài, không cần `Package.swift`.

---

## Cài đặt

```sh
git clone <repo-url> macutils
cd macutils/default-apps
```

Mọi lệnh bên dưới chạy từ trong thư mục `default-apps/`.

Có 3 cách chạy, chọn một:

### 1. Chạy trực tiếp bằng `swift` (đơn giản nhất)

```sh
swift preview.swift
swift setdefault.swift Xcode
```

Mỗi lần chạy, Swift biên dịch lại script (~0.2 giây) — đủ nhanh cho dùng thỉnh thoảng.

### 2. Chạy như lệnh thường (nhờ shebang)

```sh
chmod +x preview.swift setdefault.swift
./preview.swift json md
./setdefault.swift Xcode
```

### 3. Biên dịch sẵn thành binary (nhanh nhất, dùng ở mọi nơi)

```sh
mkdir -p ~/.local/bin
swiftc -O preview.swift    -o ~/.local/bin/ftpreview
swiftc -O setdefault.swift -o ~/.local/bin/ftdefault
# đảm bảo ~/.local/bin nằm trong PATH (thêm vào ~/.zshrc nếu chưa có):
#   export PATH="$HOME/.local/bin:$PATH"

ftpreview json
ftdefault com.microsoft.VSCode
```

Tên `ftpreview` / `ftdefault` chỉ là gợi ý — đặt tên tuỳ ý. Nhớ biên dịch lại sau khi sửa script.

---

## `preview.swift` — xem app mặc định (chỉ đọc)

```sh
swift preview.swift                  # dùng danh sách đuôi mặc định
swift preview.swift json lock md     # chỉ các đuôi chỉ định
swift preview.swift .JSON .Md        # dấu "." và chữ hoa đều được chấp nhận
swift preview.swift --help           # in hướng dẫn
```

Ví dụ kết quả:

```
━━━ .json ━━━
  UTI      : public.json
  Mặc định : Xcode  [com.apple.dt.Xcode]
  Đường dẫn: /Applications/Xcode.app
  Có thể mở bằng (11):
    • Xcode  [com.apple.dt.Xcode]
    • Visual Studio Code  [com.microsoft.VSCode]
    • Sublime Text  [com.sublimetext.4]
    • TextEdit  [com.apple.TextEdit]
    ...

━━━ .yml ━━━
  UTI      : public.yaml
  ...

━━━ .yaml ━━━
  UTI      : public.yaml
  ↪︎ cùng loại với .yml, xem ở trên
```

Ý nghĩa các dòng:

- **UTI** — *Uniform Type Identifier*, định danh loại file mà macOS dùng thật sự.
  Nhiều đuôi có thể chung một UTI (vd `yml` và `yaml` → `public.yaml`); khi đó
  app mặc định gắn với **UTI**, không gắn với đuôi.
- **dynamic** — UTI dạng `dyn.xxx` nghĩa là macOS không biết sẵn đuôi này; thường
  chưa app nào khai báo hỗ trợ, nên không đặt mặc định được bằng script.
- **Mặc định** — app mở file khi bạn double-click. Trong `[...]` là bundle ID.
- **Có thể mở bằng** — các app có khai báo hỗ trợ loại file này. Đây cũng là
  danh sách app mà `setdefault.swift` chấp nhận làm app đích.

Mẹo: dùng `preview.swift` để tra **bundle ID** chính xác của app trước khi gọi
`setdefault.swift`.

---

## `setdefault.swift` — đặt app mặc định

```sh
swift setdefault.swift <app> [đuôi1 đuôi2 ...]
swift setdefault.swift --help
```

### Cách chỉ định `<app>`

Script thử lần lượt theo thứ tự sau, gặp cái nào khớp trước thì dùng:

| Dạng | Ví dụ | Ghi chú |
| --- | --- | --- |
| Đường dẫn `.app` | `"/Applications/Visual Studio Code.app"`, `~/Applications/Foo.app` | Hỗ trợ `~` |
| Bundle ID | `com.microsoft.VSCode` | **Khuyên dùng** — chính xác, không phụ thuộc vị trí cài |
| Tên app | `Xcode`, `"Sublime Text"` | Tìm `<tên>.app` trong `/Applications`, `/Applications/Utilities`, `/System/Applications`, `/System/Applications/Utilities`, `~/Applications` |

Tên có dấu cách phải đặt trong ngoặc kép.

### Ví dụ

```sh
# Đặt VS Code mở toàn bộ danh sách đuôi mặc định
swift setdefault.swift com.microsoft.VSCode

# Chỉ đổi json và md sang Sublime Text
swift setdefault.swift "Sublime Text" json md

# Thêm đuôi tuỳ ý (đuôi app không hỗ trợ sẽ được bỏ qua)
swift setdefault.swift com.apple.dt.Xcode swift plist lock
```

Ví dụ kết quả:

```
App đích : Visual Studio Code  [com.microsoft.VSCode]
Đường dẫn: /Applications/Visual Studio Code.app

.json: Xcode → Visual Studio Code ✅
.md: ✔️  đã mở bằng Visual Studio Code sẵn rồi
.php: ⏭️  bỏ qua — Visual Studio Code không hỗ trợ loại file này
.yaml: Xcode → Visual Studio Code ✅
.yml: ↪︎  cùng loại với .yaml (public.yaml), đã xử lý ở trên

Tổng kết: ✅ 2 đã đổi · ✔️ 1 giữ nguyên · ⏭️ 1 bỏ qua · ❌ 0 lỗi/không đổi
```

### Hành vi chi tiết

1. **Chuẩn hoá đuôi**: bỏ dấu `.` đầu, chuyển chữ thường, bỏ đuôi rỗng, gộp đuôi trùng
   lặp (giữ thứ tự nhập).
2. **Gộp theo UTI**: đuôi thứ hai cùng UTI với đuôi đã xử lý được báo `↪︎` và bỏ qua
   (không tính vào tổng kết) — vì đổi một đuôi là đổi luôn cả loại.
3. **Đã là mặc định** → `✔️` giữ nguyên, không gọi API.
4. **App đích không khai báo hỗ trợ** loại file → `⏭️` bỏ qua. Script không ép app
   mở loại file nó không đăng ký.
5. **Đổi tuần tự từng loại**: mỗi lần đổi, macOS có thể hiện hộp thoại xác nhận
   *"Do you want to change the default application…?"*. Script **chờ** bạn trả lời
   hộp thoại đó rồi mới sang loại kế tiếp.
   - Chọn đồng ý → `✅`.
   - Chọn giữ app cũ → `⚠️ vẫn là …` (tính là lỗi/không đổi).
   - API trả lỗi → `❌ giữ <app cũ> — <lý do>`.

### Mã thoát (exit code)

| Mã | Khi nào |
| --- | --- |
| `0` | Thành công, không đuôi nào lỗi (kể cả khi chỉ có bỏ qua / giữ nguyên), hoặc `--help` |
| `1` | Thiếu tham số, không tìm thấy app, hoặc có ít nhất một đuôi `❌`/`⚠️` |

Nhờ vậy có thể dùng trong script khác:

```sh
swift setdefault.swift com.microsoft.VSCode json md || echo "Có loại file chưa đổi được"
```

---

## Mẹo & xử lý sự cố

- **`❌ Không tìm thấy app`** — kiểm tra lại tên/đường dẫn, hoặc tra bundle ID:
  ```sh
  osascript -e 'id of app "Visual Studio Code"'
  mdls -name kMDItemCFBundleIdentifier -r "/Applications/Visual Studio Code.app"
  ```
- **Luôn `⏭️ bỏ qua`** — app đích không đăng ký loại file đó trong `Info.plist`.
  Chạy `preview.swift <đuôi>` để xem những app nào được phép.
- **Đổi xong nhưng Finder vẫn mở app cũ** — một file cụ thể có thể đã được gán app
  riêng (Get Info → Open with, *không* bấm Change All). Gán riêng theo file được
  ưu tiên hơn mặc định theo loại.
- **App vừa cài không xuất hiện** — buộc LaunchServices đăng ký lại app:
  ```sh
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Ten App.app"
  ```
- **Hoàn tác** — chạy lại `setdefault.swift` với app cũ (xem bằng `preview.swift`
  trước khi đổi để ghi nhớ app cũ).

---

## Tuỳ biến

Danh sách đuôi mặc định khai báo ở đầu **mỗi** script:

```swift
let defaultExts = ["json", "md", "php", "js", "ts", "xml", "yaml", "yml", "sql"]
```

Hai script chạy độc lập (`swift file.swift` chỉ biên dịch một file), nên khi sửa
danh sách cần sửa **cả hai** file để chúng khớp nhau.

---

## Cấu trúc thư mục

```
default-apps/
├── preview.swift      # xem app mặc định (chỉ đọc)
├── setdefault.swift   # đặt app mặc định
└── README.md          # tài liệu này
```
