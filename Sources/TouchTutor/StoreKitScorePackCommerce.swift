import Foundation
import StoreKit

@MainActor
final class StoreKitScorePackCommerce: ScorePackCommerce {
  private var loadedProducts: [String: Product] = [:]

  func products(for identifiers: Set<String>) async throws -> [ScorePackProduct] {
    let products = try await Product.products(for: identifiers)
    let packs = products.filter { $0.type == .nonConsumable }
    loadedProducts = Dictionary(uniqueKeysWithValues: packs.map { ($0.id, $0) })
    return packs.map {
      ScorePackProduct(id: $0.id, displayName: $0.displayName, displayPrice: $0.displayPrice)
    }
  }

  func purchase(productID: String) async throws -> ScorePackPurchaseResult {
    guard let product = loadedProducts[productID] else {
      throw PurchaseError.unavailable
    }
    switch try await product.purchase() {
    case .success(let result):
      guard case .verified(let transaction) = result,
        transaction.productType == .nonConsumable
      else {
        throw PurchaseError.verificationFailed
      }
      return .purchased(Self.transaction(transaction))
    case .pending:
      return .pending
    case .userCancelled:
      return .cancelled
    @unknown default:
      throw PurchaseError.unavailable
    }
  }

  func currentEntitlements() async -> Set<String> {
    var identifiers: Set<String> = []
    for await result in Transaction.currentEntitlements {
      guard case .verified(let transaction) = result,
        transaction.productType == .nonConsumable,
        transaction.revocationDate == nil
      else { continue }
      identifiers.insert(transaction.productID)
    }
    return identifiers
  }

  func updates() -> AsyncStream<VerifiedScorePackTransaction> {
    AsyncStream { continuation in
      let task = Task {
        for await result in Transaction.updates {
          guard !Task.isCancelled else { break }
          guard case .verified(let transaction) = result,
            transaction.productType == .nonConsumable
          else { continue }
          continuation.yield(Self.transaction(transaction))
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  func restore() async throws {
    try await AppStore.sync()
  }

  private static func transaction(_ transaction: Transaction) -> VerifiedScorePackTransaction {
    VerifiedScorePackTransaction(
      productID: transaction.productID,
      isRevoked: transaction.revocationDate != nil,
      finish: { await transaction.finish() }
    )
  }

  private enum PurchaseError: LocalizedError {
    case unavailable
    case verificationFailed

    var errorDescription: String? {
      switch self {
      case .unavailable:
        L10n.string("This pack is currently unavailable. Please try again later.")
      case .verificationFailed:
        L10n.string("The purchase could not be verified. Please try restoring purchases.")
      }
    }
  }
}
