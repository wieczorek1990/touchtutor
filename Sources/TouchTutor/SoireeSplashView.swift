import SwiftUI

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

struct SoireeSplashView: View {
  @Environment(\.colorScheme) private var colorScheme

  #if os(macOS)
    @State private var logoImage: NSImage?
    @State private var logoImageWhite: NSImage?
  #else
    @State private var logoImage: UIImage?
    @State private var logoImageWhite: UIImage?
  #endif

  var body: some View {
    ZStack {
      PlatformColors.windowBackground
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      VStack(alignment: .center, spacing: 16) {
        #if os(macOS)
          let image = colorScheme == .dark ? logoImageWhite : logoImage
          if let nsImage = image {
            Image(nsImage: nsImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 120, height: 120)
          } else {
            Image(systemName: "guitars")
              .font(.system(size: 80, weight: .bold))
              .foregroundColor(.primary)
              .frame(width: 120, height: 120)
          }
        #else
          let image = colorScheme == .dark ? logoImageWhite : logoImage
          if let uiImage = image {
            Image(uiImage: uiImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 120, height: 120)
          } else {
            Image(systemName: "guitars")
              .font(.system(size: 80, weight: .bold))
              .foregroundColor(.primary)
              .frame(width: 120, height: 120)
          }
        #endif

        Text("Soiree", bundle: .module)
          .font(.system(size: 28, weight: .semibold))
          .foregroundColor(.primary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .ignoresSafeArea()
    }
    .edgesIgnoringSafeArea(.all)
  }

  #if os(macOS)
    init() {
      _logoImage = State(wrappedValue: Self.loadLogo("soiree_logo"))
      _logoImageWhite = State(wrappedValue: Self.loadLogo("soiree_logo_white"))
    }

    private static func loadLogo(_ name: String) -> NSImage? {
      if let url = Bundle.main.url(forResource: name, withExtension: "png") {
        return NSImage(contentsOf: url)
      }
      if let url = Bundle.module.url(forResource: name, withExtension: "png") {
        return NSImage(contentsOf: url)
      }
      return nil
    }
  #else
    init() {
      _logoImage = State(wrappedValue: Self.loadLogo("soiree_logo"))
      _logoImageWhite = State(wrappedValue: Self.loadLogo("soiree_logo_white"))
    }

    private static func loadLogo(_ name: String) -> UIImage? {
      if let url = Bundle.main.url(forResource: name, withExtension: "png") {
        return UIImage(contentsOfFile: url.path)
      }
      return nil
    }
  #endif
}
