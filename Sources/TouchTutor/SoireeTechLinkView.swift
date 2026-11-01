import SwiftUI

struct SoireeTechLinkView: View {
  var body: some View {
    if let url = URL(string: "https://soiree.tech") {
      Link(destination: url) {
        HStack(spacing: 4) {
          Image(systemName: "globe")
            .font(.system(size: 11, weight: .medium))

          Text("soiree.tech")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: true)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(PlatformColors.controlBackground.opacity(0.7))
        .clipShape(Capsule())
        .contentShape(Capsule())
      }
      .buttonStyle(.plain)
      .help(L10n.string("Open https://soiree.tech"))
    }
  }
}
