import SwiftUI

struct SplashView: View {
  @State private var opacity: Double = 1.0

  var body: some View {
    ZStack {
      PlatformColors.windowBackground
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      VStack(alignment: .center, spacing: 16) {
        MusicNoteLogoView(size: 120)

        Text("TouchTutor", bundle: .module)
          .font(.system(size: 28, weight: .semibold))
          .foregroundColor(.primary)
      }
    }
    .edgesIgnoringSafeArea(.all)
    .opacity(opacity)
    .onAppear {
      withAnimation(.easeOut(duration: 0.8).delay(2.0)) {
        opacity = 0
      }
    }
  }
}
