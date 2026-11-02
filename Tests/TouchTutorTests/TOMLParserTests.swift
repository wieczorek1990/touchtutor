import Foundation
import Testing
@testable import TouchTutor

struct TOMLParserTests {

  // MARK: - Simple array of tables (scores)

  @Test func parseSimpleScores() {
    let toml = """
      [[scores]]
      id = "zanarkand"
      title = "To Zanarkand"
      artist = "Nobuo Uematsu"
      album = "Final Fantasy X"

      [[scores]]
      id = "eyes_on_me"
      title = "Eyes On Me"
      artist = "Nobuo Uematsu"
      album = "Final Fantasy VIII"
      """

    let tables = TOMLParser.parse(toml)
    #expect(tables.count == 2)

    let first = tables[0]
    #expect(first["id"] as? String == "zanarkand")
    #expect(first["title"] as? String == "To Zanarkand")
    #expect(first["artist"] as? String == "Nobuo Uematsu")
    #expect(first["album"] as? String == "Final Fantasy X")

    let second = tables[1]
    #expect(second["id"] as? String == "eyes_on_me")
    #expect(second["title"] as? String == "Eyes On Me")
  }

  @Test func parseScoresWithComments() {
    let toml = """
      # This is a comment
      [[scores]]
      id = "test"
      title = "Test"
      # Another comment
      artist = "Artist"
      album = "Album"
      """

    let tables = TOMLParser.parse(toml)
    #expect(tables.count == 1)
    #expect(tables[0]["id"] as? String == "test")
  }

  @Test func parseEmptyInput() {
    let tables = TOMLParser.parse("")
    #expect(tables.isEmpty)
  }

  @Test func parseOnlyComments() {
    let toml = """
      # Comment 1
      # Comment 2
      """
    let tables = TOMLParser.parse(toml)
    #expect(tables.isEmpty)
  }

  // MARK: - Nested arrays (score packs)

  @Test func parseNestedPacks() {
    let toml = """
      [[packs]]
      id = "tech.soiree.touchtutor.scorepacks.finalfantasy"
      title = "Final Fantasy"
      color = "teal"

      [[packs.scores]]
      id = "aeriths_theme"

      [[packs.scores]]
      id = "tifas_theme"
      """

    let tables = TOMLParser.parse(toml)
    #expect(tables.count == 1)

    let pack = tables[0]
    #expect(pack["id"] as? String == "tech.soiree.touchtutor.scorepacks.finalfantasy")
    #expect(pack["title"] as? String == "Final Fantasy")
    #expect(pack["color"] as? String == "teal")

    let scores = pack["scores"] as? [[String: Any]]
    #expect(scores?.count == 2)
    #expect(scores?[0]["id"] as? String == "aeriths_theme")
    #expect(scores?[1]["id"] as? String == "tifas_theme")
  }

  @Test func parseMultiplePacks() {
    let toml = """
      [[packs]]
      id = "pack1"
      title = "Pack One"
      color = "blue"

      [[packs.scores]]
      id = "score1"

      [[packs]]
      id = "pack2"
      title = "Pack Two"
      color = "red"

      [[packs.scores]]
      id = "score2"
      """

    let tables = TOMLParser.parse(toml)
    #expect(tables.count == 2)

    // First pack
    #expect(tables[0]["id"] as? String == "pack1")
    let scores1 = tables[0]["scores"] as? [[String: Any]]
    #expect(scores1?.count == 1)
    #expect(scores1?[0]["id"] as? String == "score1")

    // Second pack
    #expect(tables[1]["id"] as? String == "pack2")
    let scores2 = tables[1]["scores"] as? [[String: Any]]
    #expect(scores2?.count == 1)
    #expect(scores2?[0]["id"] as? String == "score2")
  }

  // MARK: - Value parsing

  @Test func parseBooleanValues() {
    let toml = """
      [[items]]
      name = "item1"
      active = true

      [[items]]
      name = "item2"
      active = false
      """

    let tables = TOMLParser.parse(toml)
    #expect(tables[0]["active"] as? Bool == true)
    #expect(tables[1]["active"] as? Bool == false)
  }

  @Test func parseNumericValues() {
    let toml = """
      [[items]]
      name = "item1"
      count = 42
      price = 1.99
      """

    let tables = TOMLParser.parse(toml)
    #expect(tables[0]["count"] as? Int == 42)
    #expect(tables[0]["price"] as? Double == 1.99)
  }

  // MARK: - ScoreItem.fromTOML

  @Test func scoreItemFromTOML() {
    let table: [String: Any] = [
      "id": "test",
      "title": "Test Score",
      "artist": "Test Artist",
      "album": "Test Album"
    ]

    let item = ScoreItem.fromTOML(table)
    #expect(item?.id == "test")
    #expect(item?.filename == "test.xml")
    #expect(item?.artist == "Test Artist")
  }

  @Test func scoreItemFromTOML_minimalFields() {
    let table: [String: Any] = [
      "id": "test"
    ]
    let item = ScoreItem.fromTOML(table)
    #expect(item != nil)
    #expect(item?.id == "test")
    #expect(item?.title == "test")
    #expect(item?.artist == "")
    #expect(item?.album == "")
  }

  @Test func scoreItemFromTOML_missingID() {
    let table: [String: Any] = [
      "title": "Test"
    ]
    let item = ScoreItem.fromTOML(table)
    #expect(item == nil)
  }

  // MARK: - ScorePack.fromTOML

  @Test func scorePackFromTOML() {
    let table: [String: Any] = [
      "id": "test.pack",
      "title": "Test Pack",
      "color": "blue",
      "scores": [
        [
          "id": "score1"
        ] as [String: Any]
      ]
    ]

    let pack = ScorePack.fromTOML(table)
    #expect(pack?.id == "test.pack")
    #expect(pack?.scores.count == 1)
    #expect(pack?.scores[0].id == "score1")
    #expect(pack?.scores[0].filename == "score1.xml")
  }

  @Test func scorePackFromTOML_missingScores() {
    let table: [String: Any] = [
      "id": "test.pack",
      "title": "Test Pack"
    ]
    let pack = ScorePack.fromTOML(table)
    #expect(pack == nil)
  }

  // MARK: - Integration: loading from bundle

  @Test func loadScoresFreeResource() {
    let toml = TOMLParser.loadResource("scores_free")
    #expect(toml != nil)
    #expect(toml?.contains("zanarkand") == true)
  }

  @Test func loadScorePacksResource() {
    let toml = TOMLParser.loadResource("score_packs")
    #expect(toml != nil)
    #expect(toml?.contains("finalfantasy") == true)
  }

  @Test func loadTestScoresResource() {
    let toml = TOMLParser.loadResource("scores_test")
    #expect(toml != nil)
    #expect(toml?.contains("test") == true)
  }

  @Test func loadTestScorePacksResource() {
    let toml = TOMLParser.loadResource("score_packs_test")
    #expect(toml != nil)
    #expect(toml?.contains("cmajor") == true)
  }

  // MARK: - Default scores integration

  @Test func defaultScoresLoadedFromTOML() {
    let scores = ScoreItem.defaultScores
    #expect(!scores.isEmpty)

    let ids = scores.map(\.id)
    #expect(ids.contains("zanarkand"))
    #expect(ids.contains("eyes_on_me"))
    #expect(ids.contains("prelude"))
  }

  #if DEBUG
  @Test func testScoresIncludedInDebug() {
    let scores = ScoreItem.defaultScores
    let ids = scores.map(\.id)
    #expect(ids.contains("test"))
    #expect(ids.contains("test_long_title"))
  }
  #endif

  // MARK: - ScorePack catalog integration

  @Test func scorePackCatalogLoadedFromTOML() {
    let packs = ScorePack.catalog
    #expect(!packs.isEmpty)

    let ids = packs.map(\.id)
    #expect(ids.contains("tech.soiree.touchtutor.scorepacks.finalfantasy.1"))
  }

  #if DEBUG
  @Test func testScorePacksIncludedInDebug() {
    let packs = ScorePack.catalog
    let ids = packs.map(\.id)
    #expect(ids.contains("tech.soiree.touchtutor.scorepacks.cmajor.test"))
  }
  #endif
}
