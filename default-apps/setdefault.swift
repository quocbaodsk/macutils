#!/usr/bin/env swift
// setdefault.swift — Đặt app mặc định cho các đuôi file
// Cách dùng:
//   swift setdefault.swift <app>                 → dùng danh sách đuôi mặc định
//   swift setdefault.swift <app> json md lock    → chỉ các đuôi chỉ định
// <app> có thể là:
//   • bundle ID : com.apple.dt.Xcode   (khuyên dùng)
//   • đường dẫn : "/Applications/Xcode.app"  (hỗ trợ cả ~/...)
//   • tên app   : "Xcode"  (tìm trong /Applications, /System/Applications, ~/Applications và Utilities)
//
// - Đuôi file mà app đích không hỗ trợ sẽ được BỎ QUA.
// - Đổi lần lượt từng loại → macOS hỏi xác nhận từng hộp thoại một.
// - Các đuôi cùng loại (vd yml/yaml) chỉ xử lý một lần; đuôi trùng lặp bị gộp.
// - Mã thoát: 0 nếu không có lỗi, 1 nếu sai tham số / không tìm thấy app / có đuôi đổi thất bại.

// Usage: swift setdefault.swift <app> [extension1 extension2 ...]
// Example: swift setdefault.swift com.apple.dt.Xcode json md

import AppKit
import UniformTypeIdentifiers

let defaultExts = ["json", "md", "php", "js", "ts", "xml", "yaml", "sql"]

let args = Array(CommandLine.arguments.dropFirst())
let usage = """
Cách dùng: swift setdefault.swift <app> [đuôi1 đuôi2 ...]
  <app> có thể là bundle ID, đường dẫn .app, hoặc tên app.
  Không truyền đuôi file → dùng danh sách mặc định:
  \(defaultExts.joined(separator: ", "))
"""
if args.contains(where: { $0 == "-h" || $0 == "--help" }) {
    print(usage)
    exit(0)
}
guard !args.isEmpty else {
    print(usage)
    exit(1)
}

let ws = NSWorkspace.shared
let fm = FileManager.default

// Chuẩn hoá: bỏ dấu ".", viết thường, bỏ rỗng, khử trùng lặp nhưng giữ thứ tự.
func normalize(_ raw: [String]) -> [String] {
    var seen = Set<String>()
    return raw
        .map { ($0.hasPrefix(".") ? String($0.dropFirst()) : $0).lowercased() }
        .filter { !$0.isEmpty && seen.insert($0).inserted }
}

let appArg = args[0]
let exts = normalize(args.count > 1 ? Array(args.dropFirst()) : defaultExts)

// MARK: - Hàm hỗ trợ

@MainActor
func resolveApp(_ s: String) -> URL? {
    let path = (s as NSString).expandingTildeInPath
    if fm.fileExists(atPath: path) { return URL(fileURLWithPath: path) }
    if let u = ws.urlForApplication(withBundleIdentifier: s) { return u }
    let home = NSHomeDirectory()
    let dirs = ["/Applications", "/Applications/Utilities", "/System/Applications",
                "/System/Applications/Utilities", home + "/Applications"]
    for dir in dirs {
        let p = "\(dir)/\(s).app"
        if fm.fileExists(atPath: p) { return URL(fileURLWithPath: p) }
    }
    return nil
}

func name(_ u: URL?) -> String {
    u.map { $0.deletingPathExtension().lastPathComponent } ?? "(không có)"
}

func bundleID(_ u: URL) -> String {
    Bundle(url: u)?.bundleIdentifier ?? ""
}

// MARK: - Xác định app đích

guard let appURL = resolveApp(appArg) else {
    fputs("❌ Không tìm thấy app: \(appArg)\n", stderr)
    exit(1)
}

let appPath = appURL.standardizedFileURL.path
let bid = bundleID(appURL)
print("App đích : \(name(appURL))  [\(bid.isEmpty ? "?" : bid)]")
print("Đường dẫn: \(appURL.path)\n")

// So sánh theo đường dẫn trước (rẻ), rồi mới đến bundle ID; app đích đã tính sẵn ở trên.
@MainActor
func isTarget(_ u: URL?) -> Bool {
    guard let u = u else { return false }
    if u.standardizedFileURL.path == appPath { return true }
    return !bid.isEmpty && bundleID(u) == bid
}

// `try await ws.setDefaultApplication(...)` resolves to the callback overload with a nil
// handler, so it neither waits for the user's confirmation dialog nor surfaces errors.
@MainActor
func setDefault(_ app: URL, for type: UTType) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
        // @Sendable: AppKit calls this off the main thread; without it the closure would
        // inherit main-actor isolation and could trip Swift 6's runtime isolation check.
        ws.setDefaultApplication(at: app, toOpen: type) { @Sendable error in
            if let error = error { cont.resume(throwing: error) } else { cont.resume() }
        }
    }
}

// MARK: - Thực hiện (tuần tự)

var okCount = 0, skipCount = 0, sameCount = 0, failCount = 0
var handledUTIs: [String: String] = [:]   // UTI → đuôi đã xử lý

for ext in exts {
    guard let t = UTType(filenameExtension: ext) else {
        print(".\(ext): ❌ không xác định được loại file")
        failCount += 1
        continue
    }

    // Đuôi cùng loại với đuôi đã xử lý (vd yml ↔ yaml)
    if let first = handledUTIs[t.identifier] {
        print(".\(ext): ↪︎  cùng loại với .\(first) (\(t.identifier)), đã xử lý ở trên")
        continue
    }
    handledUTIs[t.identifier] = ext

    // Đã là mặc định thì chắc chắn được hỗ trợ → khỏi quét danh sách app
    let current = ws.urlForApplication(toOpen: t)
    if isTarget(current) {
        print(".\(ext): ✔️  đã mở bằng \(name(appURL)) sẵn rồi")
        sameCount += 1
        continue
    }

    // Bỏ qua nếu app đích không hỗ trợ
    if !ws.urlsForApplications(toOpen: t).contains(where: isTarget) {
        print(".\(ext): ⏭️  bỏ qua — \(name(appURL)) không hỗ trợ loại file này")
        skipCount += 1
        continue
    }

    let before = name(current)
    do {
        try await setDefault(appURL, for: t)
        let after = ws.urlForApplication(toOpen: t)
        if isTarget(after) {
            print(".\(ext): \(before) → \(name(after)) ✅")
            okCount += 1
        } else {
            print(".\(ext): ⚠️  vẫn là \(name(after)) (có thể bạn đã chọn giữ app cũ)")
            failCount += 1
        }
    } catch {
        print(".\(ext): ❌ giữ \(before) — \(error.localizedDescription)")
        failCount += 1
    }
}

print("\nTổng kết: ✅ \(okCount) đã đổi · ✔️ \(sameCount) giữ nguyên · ⏭️ \(skipCount) bỏ qua · ❌ \(failCount) lỗi/không đổi")
exit(failCount > 0 ? 1 : 0)
