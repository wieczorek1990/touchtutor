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
        ScrollView {
          PianoContentView(viewModel: viewModel)
            .frame(maxWidth: .infinity)
            .padding(18)
        }
        .background(PlatformColors.windowBackground)

        // Splash overlay — outside ScrollView so it fills the full screen
        if splashPhase != .done {
          ZStack {
            SoireeSplashView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .opacity(splashPhase == .soiree ? 1 : 0)

            TouchTutorSplashView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .opacity(splashPhase != .soiree ? 1 : 0)
          }
          .transition(.opacity)
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
      .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    #else
      PianoContentView(viewModel: viewModel)
        .frame(width: 366, height: 518, alignment: .top)
        .padding(.top, 0)
        .padding(18)
        .background(PlatformColors.windowBackground)
        .preferredColorScheme(
          appearance == "dark"
            ? .dark : appearance == "light" ? .light : systemAppearance.colorScheme
        )
        .onAppear {
          NSApp.setActivationPolicy(.regular)
          NSApp.activate(ignoringOtherApps: true)
          centerMainWindow()
        }
    #endif
  }
}
