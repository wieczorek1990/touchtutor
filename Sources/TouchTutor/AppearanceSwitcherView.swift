import SwiftUI

struct AppearanceSwitcherView: View {
  @AppStorage("appearance") private var appearance = "system"

  var body: some View {
    HStack(spacing: 2) {
      appearanceButton("■", dark: true)
      Text("|")
        .foregroundColor(.secondary)
        .accessibilityHidden(true)
      appearanceButton("□", dark: false)
      Text("|")
        .foregroundColor(.secondary)
        .accessibilityHidden(true)
      Button {
        appearance = "system"
      } label: {
        Text("Auto", bundle: .module)
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(.primary)
          .padding(.horizontal, 4)
          .frame(height: 26)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help(L10n.string("Follow system appearance"))
      .accessibilityAddTraits(appearance == "system" ? [.isSelected] : [])
    }
    .font(.system(size: 16, weight: .medium))
    .padding(.horizontal, 4)
    .background(PlatformColors.controlBackground.opacity(0.7))
    .clipShape(Capsule())
    .fixedSize()
    .accessibilityElement(children: .contain)
    .accessibilityLabel(L10n.string("Appearance"))
  }

  private func appearanceButton(_ symbol: String, dark: Bool) -> some View {
    Button {
      appearance = dark ? "dark" : "light"
    } label: {
      Text(symbol)
        .foregroundColor(.primary)
        .frame(width: 24, height: 26)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .help(L10n.string(dark ? "Switch to Dark appearance" : "Switch to Light appearance"))
    .accessibilityLabel(L10n.string(dark ? "Dark" : "Light"))
    .accessibilityAddTraits(appearance == (dark ? "dark" : "light") ? [.isSelected] : [])
  }
}
