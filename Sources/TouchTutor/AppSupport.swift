import Foundation

#if os(macOS)
  import AppKit
#endif

enum L10n {
  static func string(_ key: String) -> String {
    Bundle.module.localizedString(forKey: key, value: key, table: nil)
  }

  static func format(_ key: String, _ args: CVarArg...) -> String {
    String(format: string(key), locale: Locale.current, arguments: args)
  }
}

#if os(macOS)

  @MainActor
  private var mainWindow: NSWindow? {
    NSApp.windows.first(where: { $0.canBecomeMain || $0.isVisible }) ?? NSApp.windows.first
  }

  @MainActor
  func centerMainWindow() {
    mainWindow?.center()
  }

  final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)

      if let logoURL = Bundle.module.url(forResource: "logo", withExtension: "svg")
        ?? Bundle.main.url(forResource: "logo", withExtension: "svg"),
        let data = try? Data(contentsOf: logoURL),
        let iconImage = SVGRenderer.image(fromSVG: data)
      {
        NSApp.applicationIconImage = iconImage
      } else if let data = try? Data(contentsOf: URL(fileURLWithPath: "Resources/logo.svg")),
        let iconImage = SVGRenderer.image(fromSVG: data)
      {
        NSApp.applicationIconImage = iconImage
      }

      DispatchQueue.main.async {
        centerMainWindow()
        mainWindow?.makeKeyAndOrderFront(nil)
      }
    }
  }

#endif

#if !SWIFT_PACKAGE
  extension Bundle {
    static let module = Bundle.main
  }
#endif
