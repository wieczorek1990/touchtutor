import Foundation
import Testing
@testable import TouchTutor

struct ImportedScoreLibraryTests {
    private let xml = """
    <score-partwise><part><measure number="1">
    <attributes><divisions>1</divisions></attributes>
    <note><pitch><step>D</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
    </measure></part></score-partwise>
    """

    @Test func importSurvivesRelaunchAndRemovalOfOriginal() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("My Score.xml")
        try Data(xml.utf8).write(to: source)
        let library = ImportedScoreLibrary(directory: root.appendingPathComponent("Library"))
        let imported = try library.importScore(from: source)
        try FileManager.default.removeItem(at: source)

        let reloaded = try ImportedScoreLibrary(directory: library.directory).loadScores()
        #expect(reloaded.count == 1)
        let item = try #require(reloaded.first)
        #expect(item.id == imported.item.id)
        #expect(item.name == "My Score")
        #expect(item.requiredProductID == nil)
        #expect(MusicXMLParser.loadScore(item: item)?.steps.first?.notes.first?.midiNote == 62)

        let moved = root.appendingPathComponent("MovedLibrary")
        try FileManager.default.moveItem(at: library.directory, to: moved)
        let movedItem = try #require(ImportedScoreLibrary(directory: moved).loadScores().first)
        #expect(movedItem.id == item.id)
        #expect(MusicXMLParser.loadScore(item: movedItem) != nil)
    }

    @Test func duplicateImportAndPersistentDeletionPreserveOriginal() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("Score.xml")
        try Data(xml.utf8).write(to: source)
        let library = ImportedScoreLibrary(directory: root.appendingPathComponent("Library"))
        let first = try library.importScore(from: source)
        let second = try library.importScore(from: source)
        #expect(first.item.id == second.item.id)
        #expect(try library.loadScores().count == 1)

        try library.deleteScore(first.item)
        #expect(try ImportedScoreLibrary(directory: library.directory).loadScores().isEmpty)
        #expect(FileManager.default.fileExists(atPath: source.path))
        let copy = try #require(first.item.importedFileURL)
        #expect(!FileManager.default.fileExists(atPath: copy.path))
    }

    @Test func invalidImportDoesNotChangeLibrary() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("Bad.xml")
        try Data("<broken>".utf8).write(to: source)
        let library = ImportedScoreLibrary(directory: root.appendingPathComponent("Library"))
        #expect(throws: (any Error).self) { try library.importScore(from: source) }
        #expect(try library.loadScores().isEmpty)
    }

    @Test func damagedIndexIsNotOverwritten() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("Score.xml")
        try Data(xml.utf8).write(to: source)
        let library = ImportedScoreLibrary(directory: root)
        let index = root.appendingPathComponent("library.json")
        let damaged = Data("damaged index".utf8)
        try damaged.write(to: index)
        #expect(throws: (any Error).self) { try library.importScore(from: source) }
        #expect(try Data(contentsOf: index) == damaged)
    }
}
