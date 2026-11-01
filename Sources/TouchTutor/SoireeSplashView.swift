import SwiftUI

struct SoireeSplashView: View {
  var body: some View {
    ZStack {
      PlatformColors.windowBackground
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      VStack(alignment: .center, spacing: 16) {
        #if os(macOS)
          MusicNoteLogoView(size: 120)
        #else
          Image("soiree_logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
        #endif

        Text("Soiree", bundle: .module)
          .font(.system(size: 28, weight: .semibold))
          .foregroundColor(.primary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .edgesIgnoringSafeArea(.all)
  }
}
