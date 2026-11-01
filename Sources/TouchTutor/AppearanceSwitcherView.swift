import SwiftUI

struct AppearanceSwitcherView: View {
  @AppStorage("appearance") private var appearance = "system"

  var body: some View {
    HStack(spacing: 2) {
      appearanceButton("■", dark: true)
        .preferredColorScheme(.light)
      Text("|")
        .foregroundColor(getDividerColor())
        .accessibilityHidden(true)
      appearanceButton("□", dark: false)
        .preferredColorScheme(.dark)
      Text("|")
        .foregroundColor(getDividerColor())
        .accessibilityHidden(true)
      Button {
        appearance = "system"
      } label: {
        Text("Auto", bundle: .module)
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(getAutoColor())
          .padding(.horizontal, 4)
          .frame(height: 26)
          .background(
            appearance == "system"
              ? Capsule().fill(Color.secondary.opacity(0.15))
              : nil
          )
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help(L10n.string("Follow system appearance"))
      .accessibilityAddTraits(appearance == "system" ? [.isSelected] : [])
    }
    .font(.system(size: 16, weight: .medium))
    .padding(.horizontal, 4)
    .background(getBackgroundColor())
    .clipShape(Capsule())
    .overlay(Capsule().stroke(getBorderColor(), lineWidth: 1))
    .fixedSize()
    .accessibilityElement(children: .contain)
    .accessibilityLabel(L10n.string("Appearance"))
  }

  private func getBackgroundColor() -> AnyShapeStyle {
    if appearance == "dark" {
      return AnyShapeStyle(.white)
    } else if appearance == "light" {
      return AnyShapeStyle(.white.opacity(0.9))
    } else {
      return AnyShapeStyle(PlatformColors.controlBackground.opacity(0.7))
    }
  }

  private func getDividerColor() -> Color {
    if appearance == "dark" {
      return Color(red: 0, green: 0, blue: 0)
    } else {
      return Color.secondary
    }
  }

  private func getBorderColor() -> Color {
    if appearance == "dark" {
      return Color(red: 0, green: 0, blue: 0)
    } else if appearance == "light" {
      return Color.secondary.opacity(0.5)
    } else {
      return Color.secondary.opacity(0.3)
    }
  }

  private func getLightColor() -> Color {
    return Color(red: 0, green: 0, blue: 0)
  }

  private func getAutoColor() -> Color {
    return Color(red: 0, green: 0, blue: 0)
  }

  private func appearanceButton(_ symbol: String, dark: Bool) -> some View {
    let isSelected = appearance == (dark ? "dark" : "light")
    return Button {
      appearance = dark ? "dark" : "light"
    } label: {
      Text(symbol)
        .foregroundColor(dark ? Color(red: 0, green: 0, blue: 0) : getLightColor())
        .frame(width: 24, height: 26)
        .background(
          isSelected
            ? Capsule().fill(Color.secondary.opacity(0.15))
            : nil
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .help(L10n.string(dark ? "Switch to Dark appearance" : "Switch to Light appearance"))
    .accessibilityLabel(L10n.string(dark ? "Dark" : "Light"))
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
  }
}
