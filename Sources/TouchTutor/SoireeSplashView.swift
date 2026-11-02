import SwiftUI
import UIKit

struct SoireeSplashView: View {
  @Environment(\.colorScheme) private var colorScheme

  @State private var logoImage: UIImage?
  @State private var logoImageWhite: UIImage?

  var body: some View {
    ZStack {
      PlatformColors.windowBackground
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      VStack(alignment: .center, spacing: 16) {
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

        Text("Soiree", bundle: .module)
          .font(.system(size: 28, weight: .semibold))
          .foregroundColor(.primary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .ignoresSafeArea()
    }
    .edgesIgnoringSafeArea(.all)
  }

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
}
