import SwiftUI

@main
struct TouchTutorApp: App {
  #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #endif
  @StateObject private var viewModel = ScorePlayerViewModel()

  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: viewModel)
        .task { await viewModel.scoreStore.start() }
    }
    #if os(macOS)
      .windowResizability(.contentSize)
      .commands {
        MacMenuCommands(viewModel: viewModel)
      }
    #endif
  }
}
