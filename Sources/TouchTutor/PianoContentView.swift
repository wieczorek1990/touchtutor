import SwiftUI

struct PianoContentView: View {
  @ObservedObject var viewModel: ScorePlayerViewModel
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    mainContent
      .sheet(isPresented: $viewModel.isShowingScoreStore) {
        ScorePackStoreView(viewModel: viewModel)
      }
  }

  private var mainContent: some View {
    VStack(spacing: 12) {
      Spacer(minLength: 44)

      HStack(spacing: 8) {
        Spacer(minLength: 6)

        if viewModel.currentScreen != .menu {
          Button(action: {
            ParentalGateManager.shared.present {
              viewModel.returnToMenu()
            }
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
        }

        Button(action: {
          viewModel.returnToMenu()
          viewModel.gameLocked = true
          ParentalGateManager.shared.present {
            // Gate passed — no additional action needed
          }
        }) {
          Image(systemName: "lock.open.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Lock game"))

        Spacer()

        AppearanceSwitcherView()

        Spacer(minLength: 6)
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
