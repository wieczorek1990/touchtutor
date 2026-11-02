import SwiftUI

struct PianoContentView: View {
  @ObservedObject var viewModel: ScorePlayerViewModel
  @Environment(\.scenePhase) private var scenePhase
  #if os(macOS)
    @State private var splashPhase: SplashPhase = .soiree
  #endif

  #if os(macOS)
    enum SplashPhase {
      case soiree, touchTutor, done
    }
  #endif

  var body: some View {
    #if os(iOS)
      mainContent
    #else
      ZStack {
        mainContent

        // Splash overlay — hidden when done so the menu is interactive
        ZStack {
          PlatformColors.windowBackground
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

          SoireeSplashView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .opacity(splashPhase == .soiree ? 1 : 0)

          TouchTutorSplashView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .opacity(splashPhase != .soiree ? 1 : 0)
        }
        .opacity(splashPhase != .done ? 1 : 0)
        .allowsHitTesting(splashPhase != .done)
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
      .sheet(isPresented: $viewModel.isShowingScoreStore) {
        ScorePackStoreView(viewModel: viewModel)
      }
    #endif
  }

  private var mainContent: some View {
    VStack(spacing: 12) {
      #if os(iOS)
        Spacer(minLength: 44)
      #endif

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
      .padding(.top, 8)
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
    #if os(iOS)
    .sheet(isPresented: $viewModel.isShowingScoreStore) {
      ScorePackStoreView(viewModel: viewModel)
    }
    #endif
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
}
