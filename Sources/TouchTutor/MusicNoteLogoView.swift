import SwiftUI

#if os(macOS)
  import AppKit
#endif

struct MusicNoteLogoView: View {
  var size: CGFloat = 36

  #if os(macOS)
    @State private var logoImage: NSImage?

    private var logoURL: URL? {
      let candidateURLs: [URL?] = [
        Bundle.module.url(forResource: "logo", withExtension: "svg"),
        Bundle.main.url(forResource: "logo", withExtension: "svg"),
        URL(fileURLWithPath: "Resources/logo.svg"),
      ]
      return candidateURLs.compactMap { $0 }.first
    }

  #endif

  var body: some View {
    #if os(macOS)
      Group {
        if let nsImage = logoImage {
          Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
            .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
        } else {
          Image(systemName: "music.note")
            .font(.system(size: size * 0.7, weight: .bold))
            .foregroundColor(Color(red: 12 / 255, green: 74 / 255, blue: 110 / 255))
        }
      }
      .onAppear { loadLogoImage() }
    #else
      Image(systemName: "music.note")
        .font(.system(size: size * 0.7, weight: .bold))
        .foregroundStyle(.blue)
        .frame(width: size, height: size)
    #endif
  }

  #if os(macOS)
    private func loadLogoImage() {
      guard logoImage == nil else { return }
      if let url = MusicNoteLogoView.logoURLStatic(),
        let data = try? Data(contentsOf: url)
      {

        logoImage = SVGRenderer.image(fromSVG: data)
      }
    }
  #endif

  init(size: CGFloat = 36) {
    self.size = size
    #if os(macOS)
      if let url = MusicNoteLogoView.logoURLStatic(),
        let data = try? Data(contentsOf: url)
      {

        _logoImage = State(wrappedValue: SVGRenderer.image(fromSVG: data))
      }
    #endif
  }

  #if os(macOS)
    private static func logoURLStatic() -> URL? {
      let candidateURLs: [URL?] = [
        Bundle.module.url(forResource: "logo", withExtension: "svg"),
        Bundle.main.url(forResource: "logo", withExtension: "svg"),
        URL(fileURLWithPath: "Resources/logo.svg"),
      ]
      return candidateURLs.compactMap { $0 }.first
    }
  #endif
}
