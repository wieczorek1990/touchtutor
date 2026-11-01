import SwiftUI

struct ContentView: View {
  @ObservedObject var viewModel: ScorePlayerViewModel
  @AppStorage("appearance") private var appearance = "system"
  #if os(macOS)
    @StateObject private var systemAppearance = SystemAppearanceObserver()
  #endif
  #if os(iOS)
    @State private var splashPhase: SplashPhase = .soiree

    enum SplashPhase {
      case soiree, touchTutor, done
    }
  #endif

  var body: some View {
    #if os(iOS)
      ZStack {
        PlatformColors.windowBackground
          .edgesIgnoringSafeArea(.all)

        PianoContentView(viewModel: viewModel)
          .frame(maxWidth: .infinity)
          .padding(18)

        // Play button overlay — only visible on menu screen
        if viewModel.currentScreen == .menu {
          VStack {
            Spacer()
            Button(action: {
              viewModel.startGame()
            }) {
              HStack(spacing: 8) {
                Image(systemName: "play.fill")
                  .font(.system(size: 16, weight: .bold))
                Text("Play", bundle: .module)
                  .font(.system(size: 17, weight: .bold, design: .rounded))
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.blue)
                  .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 3)
              )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 34)
            .padding(.bottom, 34)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .edgesIgnoringSafeArea(.all)
        }

        // Splash overlay — removed from hierarchy when done so the menu is interactive
        if splashPhase != .done {
          ZStack {
            PlatformColors.windowBackground
              .edgesIgnoringSafeArea(.all)
              .frame(maxWidth: .infinity, maxHeight: .infinity)

            SoireeSplashView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .opacity(splashPhase == .soiree ? 1 : 0)

            TouchTutorSplashView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .opacity(splashPhase != .soiree ? 1 : 0)
          }
          .edgesIgnoringSafeArea(.all)
        }
      }
      .edgesIgnoringSafeArea(.all)
      .task {
        // Show Soiree splash for 0.5s, then TouchTutor splash for 0.5s
        try? await Task.sleep(nanoseconds: 500_000_000)
        withAnimation(.easeInOut(duration: 0.2)) {
          splashPhase = .touchTutor
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
        withAnimation(.easeInOut(duration: 0.2)) {
          splashPhase = .done
        }
      }
      .preferredColorScheme(
        appearance == "dark" ? .dark : appearance == "light" ? .light : nil
      )
    #else
      PianoContentView(viewModel: viewModel)
        .frame(width: 366, height: 518, alignment: .top)
        .padding(.top, 0)
        .padding(18)
        .background(PlatformColors.windowBackground)
        .preferredColorScheme(
          appearance == "dark"
            ? .dark
            : appearance == "light"
              ? .light : systemAppearance.colorScheme
        )
        .onAppear {
          NSApp.setActivationPolicy(.regular)
          NSApp.activate(ignoringOtherApps: true)
          centerMainWindow()
        }
    #endif
  }
}
