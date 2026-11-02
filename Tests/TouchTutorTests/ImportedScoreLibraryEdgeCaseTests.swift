import Foundation
import Testing
@testable import TouchTutor

struct ImportedScoreLibraryEdgeCaseTests {
  private let xml = """
  <score-partwise><part><measure number="1">
  <attributes><divisions>1</divisions></attributes>
  <note><pitch><step>D</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
  </measure></part></score-partwise>
  """

  private let xml2 = """
  <score-partwise><part><measure number="1">
  <attributes><divisions>1</divisions></attributes>
  <note><pitch><step>E</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
  </measure></part></score-partwise>
  """

  // MARK: - Empty library

  @Test func emptyLibraryReturnsNoScores() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let scores = try library.loadScores()
    #expect(scores.isEmpty)
  }

  @Test func nonExistentDirectoryReturnsNoScores() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let library = ImportedScoreLibrary(directory: root)
    let scores = try library.loadScores()
    #expect(scores.isEmpty)
  }

  // MARK: - Multiple imports

  @Test func multipleImportsAreAllLoaded() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)

    let source1 = root.appendingPathComponent("Scores").appendingPathComponent("Score1.xml")
    let source2 = root.appendingPathComponent("Scores").appendingPathComponent("Score2.xml")
    try FileManager.default.createDirectory(at: source1.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(xml.utf8).write(to: source1)
    try Data(xml2.utf8).write(to: source2)

    let first = try library.importScore(from: source1)
    let second = try library.importScore(from: source2)

    #expect(first.item.id != second.item.id)
    let loaded = try library.loadScores()
    #expect(loaded.count == 2)
  }

  @Test func importedScoresAreMarkedAsImported() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let source = root.appendingPathComponent("Source").appendingPathComponent("Score.xml")
    try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(xml.utf8).write(to: source)

    let imported = try library.importScore(from: source)
    #expect(imported.item.isImported)
    #expect(imported.item.importedFileURL != nil)
  }

  // MARK: - Delete and re-import

  @Test func deleteAndReimportCreatesNewEntry() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let source = root.appendingPathComponent("Source").appendingPathComponent("Score.xml")
    try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(xml.utf8).write(to: source)

    let first = try library.importScore(from: source)
    try library.deleteScore(first.item)
    #expect(try library.loadScores().isEmpty)

    let second = try library.importScore(from: source)
    #expect(second.item.id != first.item.id)
    #expect(try library.loadScores().count == 1)
  }

  @Test func deletingNonImportedScoreIsNoOp() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let notImported = ScoreItem(id: "bundled", title: "Bundled", filename: "bundled.xml", artist: "Artist", album: "Album")
    try library.deleteScore(notImported)
    #expect(try library.loadScores().isEmpty)
  }

  @Test func deletingUnknownScoreIsNoOp() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let unknown = ScoreItem(
      id: "non-existent-uuid", title: "Unknown", filename: "unknown.xml",
      artist: "Artist", album: "Album", isImported: true
    )
    try library.deleteScore(unknown)
    #expect(try library.loadScores().isEmpty)
  }

  // MARK: - Import with special characters

  @Test func importScoreNameWithSpecialCharacters() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let source = root.appendingPathComponent("Source").appendingPathComponent("My Score (Copy).xml")
    try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(xml.utf8).write(to: source)

    let imported = try library.importScore(from: source)
    #expect(imported.item.title == "My Score (Copy)")
  }

  // MARK: - Library persistence

  @Test func libraryPersistsAcrossInstances() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let source = root.appendingPathComponent("Source").appendingPathComponent("Score.xml")
    try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(xml.utf8).write(to: source)

    let lib1 = ImportedScoreLibrary(directory: root)
    let imported = try lib1.importScore(from: source)

    let lib2 = ImportedScoreLibrary(directory: root)
    let loaded = try lib2.loadScores()
    #expect(loaded.count == 1)
    #expect(loaded.first?.id == imported.item.id)
  }

  // MARK: - Invalid source

  @Test func importEmptyFileFails() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let source = root.appendingPathComponent("Source").appendingPathComponent("Empty.xml")
    try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data().write(to: source)

    #expect(throws: (any Error).self) { try library.importScore(from: source) }
  }

  @Test func importNonExistentFileFails() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let source = root.appendingPathComponent("DoesNotExist.xml")

    #expect(throws: (any Error).self) { try library.importScore(from: source) }
  }

  @Test func importScoreWithNoNotesFails() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let library = ImportedScoreLibrary(directory: root)
    let source = root.appendingPathComponent("Source").appendingPathComponent("RestsOnly.xml")
    try FileManager.default.createDirectory(at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    let restsOnly = """
    <score-partwise><part><measure number="1">
    <attributes><divisions>1</divisions></attributes>
    <note><rest/><duration>1</duration></note>
    </measure></part></score-partwise>
    """
    try Data(restsOnly.utf8).write(to: source)

    #expect(throws: (any Error).self) { try library.importScore(from: source) }
  }
}
