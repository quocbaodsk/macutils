import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let alert = NSAlert()
alert.messageText = "Hello from Swift!"
alert.informativeText = "Đây là popup native macOS."
alert.alertStyle = .informational
alert.addButton(withTitle: "OK")

app.activate(ignoringOtherApps: true)
alert.runModal()
