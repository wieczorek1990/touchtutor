import SwiftUI

struct TouchTutorSplashView: View {
  var body: some View {
    ZStack {
      PlatformColors.windowBackground
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      VStack(alignment: .center, spacing: 16) {
        Image(systemName: "music.note")
          .font(.system(size: 80, weight: .bold))
          .foregroundColor(Color(red: 12 / 255, green: 74 / 255, blue: 110 / 255))

        Text("TouchTutor", bundle: .module)
          .font(.system(size: 28, weight: .semibold))
          .foregroundColor(.primary)
      }
    }
    .edgesIgnoringSafeArea(.all)
  }
}
