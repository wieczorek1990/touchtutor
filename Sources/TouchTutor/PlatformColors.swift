import SwiftUI

enum PlatformColors {
  #if os(macOS)
    static let controlBackground = Color(nsColor: .controlBackgroundColor)
    static let textBackground = Color(nsColor: .textBackgroundColor)
    static let windowBackground = Color(nsColor: .windowBackgroundColor)
  #else
    static let controlBackground = Color(uiColor: .secondarySystemBackground)
    static let textBackground = Color(uiColor: .tertiarySystemBackground)
    static let windowBackground = Color(uiColor: .systemBackground)
  #endif
}
