# macutils

Tập hợp các tool tiện ích nhỏ cho macOS. Mỗi thư mục là **một tool độc lập**,
có README hướng dẫn chi tiết riêng.

## Danh sách tool

| Tool | Mô tả | Hướng dẫn |
| --- | --- | --- |
| [`default-apps`](default-apps/) | Xem và đặt app mặc định mở các loại file (theo đuôi / UTI) | [default-apps/README.md](default-apps/README.md) |

## Bắt đầu nhanh

```sh
git clone <repo-url> macutils
cd macutils/<tool>
```

Sau đó làm theo README của tool đó.

## Thêm tool mới

1. Tạo thư mục mới ở gốc repo, tên dạng `kebab-case` mô tả việc tool làm.
2. Đặt toàn bộ mã nguồn và `README.md` chi tiết của tool vào thư mục đó.
3. Thêm một dòng vào bảng **Danh sách tool** ở trên.

```
macutils/
├── README.md          # mục lục (file này)
└── default-apps/      # mỗi tool một thư mục
    ├── README.md
    └── ...
```
