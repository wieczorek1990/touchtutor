import Foundation
import SwiftUI

struct ScorePack: Identifiable {
  let id: String
  let title: LocalizedStringResource
  let scores: [ScoreItem]
  let color: Color

  init(productID: String, title: LocalizedStringResource, color: Color = .teal, scores: [ScoreItem])
  {
    self.id = productID
    self.title = title
    self.color = color
    self.scores = scores.map { score in
      var item = score
      item.requiredProductID = productID
      return item
    }
  }

  static let catalog: [ScorePack] = {
    var packs: [ScorePack] = [
      ScorePack(
        productID: "tech.soiree.touchtutor.scorepacks.finalfantasy",
        title: "Final Fantasy",
        color: .teal,
        scores: [
          ScoreItem(
            id: "aeriths_theme", name: "Aerith's Theme",
            filename: "Aeriths theme.xml", defaultTitle: "Aerith's Theme"
          ),
          ScoreItem(
            id: "tifas_theme", name: "Tifa's Theme",
            filename: "Tifas theme.xml", defaultTitle: "Tifa's Theme"
          ),
          ScoreItem(
            id: "youre_not_alone", name: "You're Not Alone",
            filename: "You're not alone.xml", defaultTitle: "You're Not Alone"
          ),
        ]
      )
    ]
    #if DEBUG
      packs.append(
        ScorePack(
          productID: "tech.soiree.touchtutor.scorepacks.cmajor",
          title: "C Major",
          color: .orange,
          scores: [
            ScoreItem(
              id: "practice_test_scale", name: L10n.string("C Major Scale"),
              filename: "Practice - C Major Scale.xml", defaultTitle: L10n.string("C Major Scale")
            ),
            ScoreItem(
              id: "practice_test_chords", name: L10n.string("C Major Chords"),
              filename: "Practice - C Major Chords.xml", defaultTitle: L10n.string("C Major Chords")
            ),
          ]
        )
      )
    #endif
    return packs
  }()
}

struct ScorePackProduct: Equatable, Sendable {
  let id: String
  let displayName: String
  let displayPrice: String
}

struct VerifiedScorePackTransaction: Sendable {
  let productID: String
  let isRevoked: Bool
  let finish: @Sendable () async -> Void
}

enum ScorePackPurchaseResult: Sendable {
  case purchased(VerifiedScorePackTransaction)
  case pending
  case cancelled
}

@MainActor
protocol ScorePackCommerce {
  func products(for identifiers: Set<String>) async throws -> [ScorePackProduct]
  func purchase(productID: String) async throws -> ScorePackPurchaseResult
  func currentEntitlements() async -> Set<String>
  func updates() -> AsyncStream<VerifiedScorePackTransaction>
  func restore() async throws
}

struct ScorePackStoreState: Equatable {
  var products: [String: ScorePackProduct] = [:]
  var ownedProductIDs: Set<String> = []
  var pendingProductIDs: Set<String> = []
  var isLoading = false
  var isRestoring = false
  var purchasingProductID: String?
  var message: String?

  var isBusy: Bool { isLoading || isRestoring || purchasingProductID != nil }

  func canPlay(_ score: ScoreItem) -> Bool {
    guard let productID = score.requiredProductID else { return true }
    return ownedProductIDs.contains(productID)
  }
}
