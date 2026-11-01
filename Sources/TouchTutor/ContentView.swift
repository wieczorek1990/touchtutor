import SwiftUI

struct ContentView: View {
  @ObservedObject var viewModel: ScorePlayerViewModel
  @AppStorage("appearance") private var appearance = "system"
  #if os(macOS)
    @StateObject private var systemAppearance = SystemAppearanceObserver()
  #endif

  var body: some View {
    #if os(iOS)
      ScrollView {
        PianoContentView(viewModel: viewModel)
          .frame(maxWidth: .infinity)
          .padding(18)
      }
      .background(PlatformColors.windowBackground)
      .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    #else
      PianoContentView(viewModel: viewModel)
        .frame(width: 366, height: 518, alignment: .top)
        .padding(.top, 6)
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
