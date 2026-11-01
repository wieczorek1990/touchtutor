import SwiftUI

struct PianoContentView: View {
  @ObservedObject var viewModel: ScorePlayerViewModel
  @Environment(\.scenePhase) private var scenePhase
  @State private var splashPhase: SplashPhase = .soiree

  enum SplashPhase {
    case soiree, touchTutor, done
  }

  var body: some View {
    ZStack {
      if splashPhase == .done {
        VStack(spacing: 12) {
          HStack(spacing: 8) {
            if viewModel.currentScreen != .menu {
              Button(action: {
                viewModel.returnToMenu()
              }) {
                HStack(spacing: 5) {
                  Image(systemName: "chevron.backward")
                    .font(.system(size: 12, weight: .bold))
                  Text("Menu", bundle: .module)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(PlatformColors.controlBackground.opacity(0.7))
                .clipShape(Capsule())
              }
              .buttonStyle(.plain)
              .help(L10n.string("Return to Menu (Backspace / Esc)"))

              Text("|")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            }

            SoireeTechLinkView()

            Spacer()

            AppearanceSwitcherView()
          }
          .frame(height: 26)
          .layoutPriority(1)

          if viewModel.currentScreen == .menu {
            PreGameMenuView(viewModel: viewModel)
          } else {
            GamePlayView(viewModel: viewModel)
          }
        }
        .task(id: scenePhase) {
          if scenePhase == .active { await viewModel.scoreStore.refreshEntitlements() }
        }
        .sheet(isPresented: $viewModel.isShowingScoreStore) {
          ScorePackStoreView(viewModel: viewModel)
        }
        .alert(
          L10n.string("Score Library"),
          isPresented: Binding(
            get: { viewModel.libraryError != nil },
            set: { if !$0 { viewModel.libraryError = nil } }
          )
        ) {
          Button(L10n.string("OK"), role: .cancel) { viewModel.libraryError = nil }
        } message: {
          Text(viewModel.libraryError ?? "")
        }
      }

      // Splash overlay
      if splashPhase != .done {
        if splashPhase == .soiree {
          SoireeSplashView()
            .transition(.opacity)
        } else {
          TouchTutorSplashView()
            .transition(.opacity)
        }
      }
    }
    .edgesIgnoringSafeArea(.all)
    .task {
      // Show Soiree splash for 2.5s, then TouchTutor splash for 2.5s
      try? await Task.sleep(nanoseconds: 2_500_000_000)
      withAnimation(.easeInOut(duration: 0.3)) {
        splashPhase = .touchTutor
      }
      try? await Task.sleep(nanoseconds: 2_500_000_000)
      withAnimation(.easeInOut(duration: 0.3)) {
        splashPhase = .done
      }
    }
  }
}
