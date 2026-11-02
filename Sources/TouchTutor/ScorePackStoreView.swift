import SwiftUI

struct ScorePackStoreView: View {
  @ObservedObject var viewModel: ScorePlayerViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var selectedPack: ScorePack?

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        if selectedPack != nil {
          Button {
            withAnimation(.easeInOut(duration: 0.2)) {
              selectedPack = nil
            }
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "chevron.backward")
                .font(.system(size: 12, weight: .bold))
              Text("Packs", bundle: .module)
                .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.secondary)
          }
          .buttonStyle(.plain)
        } else {
          Text("Score Packs", bundle: .module)
            .font(.title2.bold())
        }
        Spacer()
        Button {
          dismiss()
        } label: {
          Text("Done", bundle: .module)
        }
        .keyboardShortcut(.cancelAction)
      }

      if let pack = selectedPack {
        ScorePackDetailView(
          pack: pack,
          product: viewModel.storeState.products[pack.id],
          isOwned: viewModel.storeState.ownedProductIDs.contains(pack.id),
          isPending: viewModel.storeState.pendingProductIDs.contains(pack.id),
          isPurchasing: viewModel.storeState.purchasingProductID == pack.id,
          isBusy: viewModel.storeState.isBusy,
          purchase: { Task { await viewModel.scoreStore.purchase(pack) } }
        )
      } else {
        VStack(spacing: 16) {
          ScrollView {
            VStack(alignment: .leading, spacing: 16) {
              Text("Buy a pack once and play its scores whenever you like.", bundle: .module)
                .foregroundStyle(.secondary)
              if viewModel.scoreStore.packs.isEmpty {
                Text("No score packs are available yet.", bundle: .module)
                  .padding(.vertical)
              }
              ForEach(viewModel.scoreStore.packs.sorted { a, b in
                let aOwned = viewModel.storeState.ownedProductIDs.contains(a.id)
                let bOwned = viewModel.storeState.ownedProductIDs.contains(b.id)
                return !aOwned && bOwned
              }) { pack in
                ScorePackRow(
                  pack: pack,
                  product: viewModel.storeState.products[pack.id],
                  isOwned: viewModel.storeState.ownedProductIDs.contains(pack.id),
                  isPending: viewModel.storeState.pendingProductIDs.contains(pack.id),
                  isPurchasing: viewModel.storeState.purchasingProductID == pack.id,
                  isBusy: viewModel.storeState.isBusy,
                  purchase: { Task { await viewModel.scoreStore.purchase(pack) } },
                  selectPack: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                      selectedPack = pack
                    }
                  }
                )
              }
              if let message = viewModel.storeState.message {
                Text(message)
                  .font(.callout)
              }
              #if DEBUG
                if viewModel.storeState.products.isEmpty, viewModel.storeState.message != nil {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Testing purchases in debug mode?", bundle: .module)
                      .font(.callout.bold())
                    let debugHint =
                      "Run the app from Xcode (⌘R) with the StoreKit configuration "
                      + "attached to the scheme so that test products load locally."
                    Text(debugHint)
                      .font(.callout)
                      .foregroundStyle(.secondary)
                  }
                  .padding()
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                }
              #endif
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .layoutPriority(-1)
          #if os(iOS)
          ScorePackStoreActions(
            state: viewModel.storeState,
            reload: { Task { await viewModel.scoreStore.loadProducts() } },
            restore: { Task { await viewModel.scoreStore.restore() } }
          )
          #endif
        }
      }
    }
    .padding(20)
    .frame(maxWidth: 400)
    .task { await viewModel.scoreStore.loadProducts() }
  }
}

private struct ScorePackRow: View {
  let pack: ScorePack
  let product: ScorePackProduct?
  let isOwned: Bool
  let isPending: Bool
  let isPurchasing: Bool
  let isBusy: Bool
  let purchase: () -> Void
  let selectPack: () -> Void

  @State private var isHovered = false
  @State private var isPressed = false

  private var backgroundColor: Color {
    if isPressed {
      pack.color.opacity(0.35)
    } else if isHovered {
      pack.color.opacity(0.22)
    } else {
      pack.color.opacity(0.12)
    }
  }

  private var strokeOpacity: Double {
    if isPressed {
      0.7
    } else if isHovered {
      0.55
    } else {
      0.4
    }
  }

  var body: some View {
    Button(action: selectPack) {
      content
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(pack.color.opacity(strokeOpacity), lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.15)) {
        isHovered = hovering
      }
    }
    .simultaneousGesture(
      pressGesture
    )
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(pack.title).font(.headline)
      ForEach(pack.scores) { score in
        Text(score.title)
          .font(.subheadline)
      }
      if isOwned {
        HStack {
          Spacer()
          Label {
            Text("Purchased", bundle: .module)
          } icon: {
            Image(systemName: "checkmark.circle.fill")
          }
          .foregroundStyle(.secondary)
        }
      } else if isPurchasing {
        ProgressView {
          Text("Purchasing…", bundle: .module)
        }
        .frame(maxWidth: .infinity, alignment: .center)
      } else if isPending {
        Text("Awaiting approval", bundle: .module)
          .foregroundStyle(.secondary)
      } else if product != nil {
        HStack {
          Spacer()
          buyButton
        }
      } else {
        Text("Currently unavailable", bundle: .module)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var buyButton: some View {
    Text("Buy for \(product!.displayPrice)", bundle: .module)
      .font(.subheadline.bold())
      .foregroundColor(.white)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(pack.color, in: Capsule())
      .disabled(isBusy)
      .highPriorityGesture(
        TapGesture().onEnded { _ in purchase() }
      )
  }

  private var pressGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { _ in
        withAnimation(.easeInOut(duration: 0.1)) {
          isPressed = true
        }
      }
      .onEnded { _ in
        withAnimation(.easeInOut(duration: 0.15)) {
          isPressed = false
        }
      }
  }
}

private struct ScorePackDetailView: View {
  let pack: ScorePack
  let product: ScorePackProduct?
  let isOwned: Bool
  let isPending: Bool
  let isPurchasing: Bool
  let isBusy: Bool
  let purchase: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            Rectangle()
              .fill(pack.color)
              .frame(width: 4)
            Text(pack.title)
              .font(.title3.bold())
          }
          .padding(.bottom, 4)

          Text("\(pack.scores.count) scores", bundle: .module)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          Divider()

          VStack(alignment: .leading, spacing: 8) {
            Text("Scores", bundle: .module)
              .font(.caption.bold())
              .foregroundStyle(.secondary)
              .padding(.top, 4)

            ForEach(pack.scores) { score in
              HStack(spacing: 8) {
                if isOwned {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                } else {
                  Image(systemName: "lock.circle")
                    .foregroundColor(.secondary)
                }
                Text(score.title)
                  .font(.subheadline)
                Spacer()
              }
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(
                pack.color.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8)
              )
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      if isOwned {
        HStack {
          Spacer()
          Label {
            Text("Purchased", bundle: .module)
          } icon: {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
          }
        }
      } else if isPurchasing {
        ProgressView {
          Text("Purchasing…", bundle: .module)
        }
        .frame(maxWidth: .infinity, alignment: .center)
      } else if isPending {
        Text("Awaiting approval", bundle: .module)
          .foregroundStyle(.secondary)
      } else if let product {
        Button(action: purchase) {
          HStack {
            Text("Buy for \(product.displayPrice)", bundle: .module)
            Spacer()
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isBusy)
      } else {
        Text("Currently unavailable", bundle: .module)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct ScorePackStoreActions: View {
  let state: ScorePackStoreState
  let reload: () -> Void
  let restore: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      if state.isLoading || state.isRestoring {
        ProgressView {
          Text(state.isRestoring ? "Restoring Purchases…" : "Loading Packs…", bundle: .module)
        }
        .frame(maxWidth: .infinity, alignment: .center)
      }
      HStack {
        Button(action: reload) {
          Text("Reload Packs", bundle: .module)
        }
        Spacer()
        Button(action: restore) {
          Text("Restore Purchases", bundle: .module)
        }
      }
      .disabled(state.isBusy)
    }
  }
}
