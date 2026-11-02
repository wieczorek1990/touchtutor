import SwiftUI

@main
struct TouchTutorApp: App {
  @StateObject private var viewModel = ScorePlayerViewModel()

  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: viewModel)
        .task {
          await viewModel.scoreStore.start()
        }
    }
  }
}
