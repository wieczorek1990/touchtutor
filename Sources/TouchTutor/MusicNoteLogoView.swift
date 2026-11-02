import SwiftUI

struct MusicNoteLogoView: View {
  var size: CGFloat = 36

  var body: some View {
    Image(systemName: "music.note")
      .font(.system(size: size * 0.7, weight: .bold))
      .foregroundStyle(.blue)
      .frame(width: size, height: size)
  }
}
