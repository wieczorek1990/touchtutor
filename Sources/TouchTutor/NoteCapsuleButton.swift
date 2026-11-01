import SwiftUI

struct NoteCapsuleButton: View {
  let pitch: ScorePitch
  let onPlay: () -> Void

  var body: some View {
    Button(action: onPlay) {
      Text(pitch.displayName)
        .font(.system(size: 15, weight: .semibold, design: .monospaced))
        .foregroundColor(.blue)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
          Capsule()
            .fill(Color.blue.opacity(0.12))
        )
        .overlay(
          Capsule()
            .stroke(Color.blue.opacity(0.32), lineWidth: 1)
        )
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .help(L10n.format("Play %@", pitch.displayName))
  }
}
