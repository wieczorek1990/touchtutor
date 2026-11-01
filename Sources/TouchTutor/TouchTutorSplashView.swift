import SwiftUI

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

struct TouchTutorSplashView: View {
  #if os(macOS)
    @State private var logoImage: NSImage?
  #else
    @State private var logoImage: UIImage?
  #endif

  var body: some View {
    ZStack {
      PlatformColors.windowBackground
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      VStack(alignment: .center, spacing: 16) {
        #if os(macOS)
          if let nsImage = logoImage {
            Image(nsImage: nsImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 120, height: 120)
          } else {
            Image(systemName: "music.note")
              .font(.system(size: 80, weight: .bold))
              .foregroundColor(Color(red: 12 / 255, green: 74 / 255, blue: 110 / 255))
              .frame(width: 120, height: 120)
          }
        #else
          if let uiImage = logoImage {
            Image(uiImage: uiImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 120, height: 120)
          } else {
            Image(systemName: "music.note")
              .font(.system(size: 80, weight: .bold))
              .foregroundColor(Color(red: 12 / 255, green: 74 / 255, blue: 110 / 255))
              .frame(width: 120, height: 120)
          }
        #endif

        Text("TouchTutor", bundle: .module)
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
      _logoImage = State(wrappedValue: Self.loadLogo())
    }

    private static func loadLogo() -> NSImage? {
      if let url = Bundle.main.url(forResource: "touchtutor_logo", withExtension: "png") {
        return NSImage(contentsOf: url)
      }
      if let url = Bundle.module.url(forResource: "touchtutor_logo", withExtension: "png") {
        return NSImage(contentsOf: url)
      }
      return nil
    }
  #else
    init() {
      _logoImage = State(wrappedValue: Self.loadLogo())
    }

    private static func loadLogo() -> UIImage? {
      if let url = Bundle.main.url(forResource: "touchtutor_logo", withExtension: "png") {
        return UIImage(contentsOfFile: url.path)
      }
      return nil
    }
  #endif
}
