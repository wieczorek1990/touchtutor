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
    var packs = loadPacksFromTOML("score_packs")
    #if DEBUG
      packs.append(contentsOf: loadPacksFromTOML("score_packs_test"))
    #endif
    return packs
  }()

  private static func loadPacksFromTOML(_ name: String) -> [ScorePack] {
    guard let toml = TOMLParser.loadResource(name) else { return [] }
    let tables = TOMLParser.parse(toml)
    var packs: [ScorePack] = []
    for table in tables {
      // Each table may be a wrapper containing a "packs" array, or a direct pack entry
      if let packsArray = table["packs"] as? [[String: Any]] {
        for entry in packsArray {
          if let pack = ScorePack.fromTOML(entry) {
            packs.append(pack)
          }
        }
      } else if let pack = ScorePack.fromTOML(table) {
        packs.append(pack)
      }
    }
    return packs
  }

  /// Create a ScorePack from a TOML table entry.
  static func fromTOML(_ table: [String: Any]) -> ScorePack? {
    guard let id = table["id"] as? String,
      let title = table["title"] as? String
    else { return nil }

    let colorName = (table["color"] as? String) ?? "teal"
    let color: Color = colorFromName(colorName)

    guard let scoresArray = table["scores"] as? [[String: Any]] else { return nil }
    var scores: [ScoreItem] = []
    for entry in scoresArray {
      if let item = ScoreItem.fromTOML(entry) {
        scores.append(item)
      }
    }

    return ScorePack(
      productID: id,
      title: LocalizedStringResource(stringLiteral: title),
      color: color,
      scores: scores
    )
  }

  private static func colorFromName(_ name: String) -> Color {
    switch name.lowercased() {
    case "teal": return .teal
    case "orange": return .orange
    case "blue": return .blue
    case "red": return .red
    case "green": return .green
    case "purple": return .purple
    case "pink": return .pink
    case "yellow": return .yellow
    case "indigo": return .indigo
    case "mint": return .mint
    default: return .teal
    }
  }
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
