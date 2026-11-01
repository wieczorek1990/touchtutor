import Foundation

@MainActor
final class ScorePackStore {
  let packs: [ScorePack]
  var onChange: ((ScorePackStoreState) -> Void)?
  private(set) var state = ScorePackStoreState() {
    didSet { onChange?(state) }
  }

  private let commerce: any ScorePackCommerce
  private let productIDs: Set<String>
  private var updatesTask: Task<Void, Never>?
  private var entitlementRevision = 0

  init(
    packs: [ScorePack] = ScorePack.catalog,
    commerce: any ScorePackCommerce = StoreKitScorePackCommerce()
  ) {
    self.packs = packs
    self.commerce = commerce
    self.productIDs = Set(packs.map(\.id))
  }

  deinit {
    updatesTask?.cancel()
  }

  func start() async {
    guard updatesTask == nil else { return }
    let updates = commerce.updates()
    updatesTask = Task { [weak self] in
      for await transaction in updates {
        guard !Task.isCancelled else { return }
        await self?.handle(transaction)
      }
    }
    await refreshEntitlements()
    await loadProducts()
  }

  func refreshEntitlements() async {
    entitlementRevision += 1
    let revision = entitlementRevision
    let identifiers = await commerce.currentEntitlements()
    guard revision == entitlementRevision else { return }
    state.ownedProductIDs = identifiers.intersection(productIDs)
    state.pendingProductIDs.subtract(state.ownedProductIDs)
  }

  func loadProducts() async {
    guard !state.isBusy else { return }
    state.isLoading = true
    state.message = nil
    guard !productIDs.isEmpty else {
      state.isLoading = false
      return
    }
    do {
      let products = try await commerce.products(for: productIDs)
      state.products = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
    } catch {
      state.message = Self.userMessage(for: error, context: L10n.string("Loading score packs"))
    }
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    state.isLoading = false
  }

  func purchase(_ pack: ScorePack) async {
    guard productIDs.contains(pack.id), !state.isBusy,
      !state.ownedProductIDs.contains(pack.id),
      !state.pendingProductIDs.contains(pack.id),
      state.products[pack.id] != nil
    else { return }
    state.purchasingProductID = pack.id
    state.message = nil
    defer { state.purchasingProductID = nil }
    do {
      switch try await commerce.purchase(productID: pack.id) {
      case .purchased(let transaction):
        await handle(transaction)
      case .pending:
        state.pendingProductIDs.insert(pack.id)
        state.message = L10n.string(
          "Purchase is awaiting approval. Your pack will unlock when approved.")
      case .cancelled:
        break
      }
    } catch {
      state.message = Self.userMessage(for: error, context: L10n.string("Purchasing score pack"))
    }
  }

  func restore() async {
    guard !state.isBusy else { return }
    state.isRestoring = true
    state.message = nil
    defer { state.isRestoring = false }
    do {
      try await commerce.restore()
      await refreshEntitlements()
      state.message =
        state.ownedProductIDs.isEmpty
        ? L10n.string("No purchased score packs were found.")
        : L10n.string("Your purchased score packs have been restored.")
    } catch {
      state.message = Self.userMessage(for: error, context: L10n.string("Restoring purchases"))
    }
  }

  private static func userMessage(for error: any Error, context: String) -> String {
    let description = error.localizedDescription
    // Generic StoreKit/NSError messages are unhelpful; replace them with context-specific guidance.
    if description == "The operation couldn't be completed."
      || description == "Unable to complete request."
    {
      return "\(context) failed. Please check your connection and try again."
    }
    return description
  }

  private func handle(_ transaction: VerifiedScorePackTransaction) async {
    guard productIDs.contains(transaction.productID) else { return }
    entitlementRevision += 1
    if transaction.isRevoked {
      state.ownedProductIDs.remove(transaction.productID)
    } else {
      state.ownedProductIDs.insert(transaction.productID)
    }
    state.pendingProductIDs.remove(transaction.productID)
    state.message = nil
    await transaction.finish()
  }
}
