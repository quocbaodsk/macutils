#!/usr/bin/env swift
// preview.swift — Xem app mặc định cho các đuôi file (CHỈ ĐỌC, không thay đổi gì)
// Cách dùng:
//   swift preview.swift              → xem danh sách mặc định
//   swift preview.swift json lock md → xem các đuôi chỉ định
//
// - Đuôi trùng lặp (vd json .JSON) chỉ hiển thị một lần.
// - Các đuôi cùng loại (vd yml/yaml) chỉ in chi tiết một lần.

// Usage: swift preview.swift [extension1 extension2 ...]
// Example: swift preview.swift json md

import AppKit
import UniformTypeIdentifiers

let defaultExts = ["json", "md", "php", "js", "ts", "xml", "yaml", "sql", "zsh"]

let args = Array(CommandLine.arguments.dropFirst())
if args.contains(where: { $0 == "-h" || $0 == "--help" }) {
    print("""
    Cách dùng: swift preview.swift [đuôi1 đuôi2 ...]
      Không truyền đuôi file → dùng danh sách mặc định:
      \(defaultExts.joined(separator: ", "))
    """)
    exit(0)
}

// Chuẩn hoá: bỏ dấu ".", viết thường, bỏ rỗng, khử trùng lặp nhưng giữ thứ tự.
func normalize(_ raw: [String]) -> [String] {
    var seen = Set<String>()
    return raw
        .map { ($0.hasPrefix(".") ? String($0.dropFirst()) : $0).lowercased() }
        .filter { !$0.isEmpty && seen.insert($0).inserted }
}

let exts = normalize(args.isEmpty ? defaultExts : args)

let ws = NSWorkspace.shared

func appInfo(_ url: URL) -> String {
    let name = url.deletingPathExtension().lastPathComponent
    let id = Bundle(url: url)?.bundleIdentifier ?? "?"
    return "\(name)  [\(id)]"
}

var shownUTIs: [String: String] = [:]   // UTI → đuôi đầu tiên đã in

for ext in exts {
    print("━━━ .\(ext) ━━━")

    guard let t = UTType(filenameExtension: ext) else {
        print("  Không xác định được loại file\n")
        continue
    }

    print("  UTI      : \(t.identifier)\(t.isDynamic ? "  (dynamic, macOS không biết sẵn)" : "")")

    if let first = shownUTIs[t.identifier] {
        print("  ↪︎ cùng loại với .\(first), xem ở trên\n")
        continue
    }
    shownUTIs[t.identifier] = ext

    if let def = ws.urlForApplication(toOpen: t) {
        print("  Mặc định : \(appInfo(def))")
        print("  Đường dẫn: \(def.path)")
    } else {
        print("  Mặc định : (không có)")
    }

    let all = ws.urlsForApplications(toOpen: t)
    if all.isEmpty {
        print("  Có thể mở bằng: (không app nào khai báo hỗ trợ)")
    } else {
        print("  Có thể mở bằng (\(all.count)):")
        for u in all { print("    • \(appInfo(u))") }
    }
    print()
}
