import Foundation
import Testing
@testable import TouchTutor

@MainActor
struct ScorePackStoreTests {
    private func pack() -> ScorePack {
        ScorePack(productID: "test.pack", title: "Test Pack", scores: [
            ScoreItem(id: "paid", name: "Paid", filename: "Nobuo Uematsu - To Zanarkand.xml",
                      defaultTitle: "Paid")
        ])
    }

    @Test func startupRestoresOnlyKnownPacksAndKeepsImportsFree() async {
        let commerce = MockScorePackCommerce()
        commerce.entitlements = ["test.pack", "unknown.pack"]
        let pack = pack()
        let store = ScorePackStore(packs: [pack], commerce: commerce)
        await store.start()
        #expect(store.state.ownedProductIDs == ["test.pack"])
        #expect(store.state.canPlay(pack.scores[0]))
        let imported = ScoreItem(id: "import", name: "Import", filename: "import.xml",
                                 defaultTitle: "Import", isImported: true)
        #expect(ScorePackStoreState().canPlay(imported))
        #expect(!ScorePackStoreState().canPlay(pack.scores[0]))
    }

    @Test func purchaseDeliversBeforeFinishingAndDoesNotChargeTwice() async {
        let commerce = MockScorePackCommerce()
        let pack = pack()
        let store = ScorePackStore(packs: [pack], commerce: commerce)
        await store.start()
        commerce.result = .purchased(VerifiedScorePackTransaction(
            productID: pack.id, isRevoked: false,
            finish: {
                await MainActor.run {
                    #expect(store.state.canPlay(pack.scores[0]))
                    commerce.finishCount += 1
                }
            }
        ))
        await store.purchase(pack)
        await store.purchase(pack)
        #expect(commerce.purchaseCount == 1)
        #expect(commerce.finishCount == 1)
        #expect(store.state.purchasingProductID == nil)
    }

    @Test func cancellationPendingAndFailureDoNotUnlock() async {
        for outcome in [ScorePackPurchaseResult.cancelled, .pending] {
            let commerce = MockScorePackCommerce()
            commerce.result = outcome
            let pack = pack()
            let store = ScorePackStore(packs: [pack], commerce: commerce)
            await store.start()
            await store.purchase(pack)
            #expect(!store.state.canPlay(pack.scores[0]))
            #expect(store.state.purchasingProductID == nil)
        }
        let commerce = MockScorePackCommerce()
        commerce.purchaseError = CocoaError(.coderInvalidValue)
        let pack = pack()
        let store = ScorePackStore(packs: [pack], commerce: commerce)
        await store.start()
        await store.purchase(pack)
        #expect(!store.state.canPlay(pack.scores[0]))
        #expect(store.state.message != nil)
    }

    @Test func restoreReplacesOwnershipAndUnavailableProductsCannotBeBought() async {
        let commerce = MockScorePackCommerce()
        commerce.offeredProducts = []
        let pack = pack()
        let store = ScorePackStore(packs: [pack], commerce: commerce)
        await store.start()
        await store.purchase(pack)
        #expect(commerce.purchaseCount == 0)
        commerce.entitlements = [pack.id]
        await store.restore()
        #expect(store.state.canPlay(pack.scores[0]))
        commerce.entitlements = []
        await store.restore()
        #expect(!store.state.canPlay(pack.scores[0]))
        #expect(commerce.restoreCount == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func deferredApprovalAndRevocationUpdateAccess() async {
        let commerce = MockScorePackCommerce()
        let pack = pack()
        let store = ScorePackStore(packs: [pack], commerce: commerce)
        await store.start()
        commerce.result = .pending
        await store.purchase(pack)
        #expect(store.state.pendingProductIDs.contains(pack.id))

        for revoked in [false, true] {
            let (finished, continuation) = AsyncStream<Void>.makeStream()
            commerce.continuation?.yield(VerifiedScorePackTransaction(
                productID: pack.id, isRevoked: revoked,
                finish: { continuation.yield(()); continuation.finish() }
            ))
            for await _ in finished { break }
            #expect(store.state.canPlay(pack.scores[0]) == !revoked)
            #expect(!store.state.pendingProductIDs.contains(pack.id))
        }
    }

    @Test func lockedScoreCannotStartThroughPlayerAndRefundClearsLoadedScore() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let commerce = MockScorePackCommerce()
        let pack = pack()
        let store = ScorePackStore(packs: [pack], commerce: commerce)
        let player = ScorePlayerViewModel(
            importedLibrary: ImportedScoreLibrary(directory: root), scoreStore: store
        )
        player.selectScore(pack.scores[0])
        player.startGame()
        #expect(player.currentScreen == .menu)
        #expect(player.score == nil)
        #expect(player.isShowingScoreStore)

        commerce.entitlements = [pack.id]
        await store.refreshEntitlements()
        #expect(player.score != nil)
        player.startGame()
        #expect(player.currentScreen == .game)
        commerce.entitlements = []
        await store.refreshEntitlements()
        #expect(player.currentScreen == .menu)
        #expect(player.score == nil)
        player.startGame()
        #expect(player.currentScreen == .menu)
    }

    @Test func paidScoresArePositionedBelowTestAndAboveDefaultScores() async {
        let pack = pack()
        let store = ScorePackStore(packs: [pack], commerce: MockScorePackCommerce())
        let player = ScorePlayerViewModel(scoreStore: store)

        #if DEBUG
        #expect(player.availableScores.first?.id == "test")
        #endif

        if let zanarkandIndex = player.availableScores.firstIndex(where: { $0.id == "zanarkand" }),
           let paidIndex = player.availableScores.firstIndex(where: { $0.id == pack.scores[0].id }) {
            #expect(paidIndex < zanarkandIndex)
        }
    }
}

@MainActor
private final class MockScorePackCommerce: ScorePackCommerce {
    var entitlements: Set<String> = []
    var offeredProducts = [ScorePackProduct(id: "test.pack", displayName: "Test", displayPrice: "€1.00")]
    var result: ScorePackPurchaseResult = .cancelled
    var purchaseError: (any Error)?
    var purchaseCount = 0
    var finishCount = 0
    var restoreCount = 0
    var continuation: AsyncStream<VerifiedScorePackTransaction>.Continuation?

    func products(for identifiers: Set<String>) async throws -> [ScorePackProduct] {
        offeredProducts
    }

    func purchase(productID: String) async throws -> ScorePackPurchaseResult {
        purchaseCount += 1
        if let purchaseError { throw purchaseError }
        return result
    }

    func currentEntitlements() async -> Set<String> { entitlements }

    func updates() -> AsyncStream<VerifiedScorePackTransaction> {
        AsyncStream { continuation = $0 }
    }

    func restore() async throws { restoreCount += 1 }
}
