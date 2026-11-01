import Foundation
import XCTest
@testable import TouchTutor

final class ScoreLoadingTests: XCTestCase {
    func testBundledScoresContainNotes() throws {
        for item in ScoreItem.defaultScores {
            let score = try XCTUnwrap(MusicXMLParser.loadScore(item: item))
            XCTAssertFalse(score.steps.isEmpty)
        }
    }

    func testImportedScoreReloadsFromOriginalPath() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("custom.xml")
        let xml = """
        <score-partwise><part><measure number="1">
        <attributes><divisions>1</divisions></attributes>
        <note><pitch><step>D</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
        </measure></part></score-partwise>
        """
        try Data(xml.utf8).write(to: url)
        let item = ScoreItem(id: url.path, name: "Custom", filename: url.lastPathComponent,
                             defaultTitle: "Custom", defaultArtist: "Custom Artist", defaultAlbum: "Custom Album",
                             isImported: true)
        let score = try XCTUnwrap(MusicXMLParser.loadScore(item: item))
        XCTAssertEqual(score.title, "Custom")
        XCTAssertEqual(score.steps.first?.notes.first?.midiNote, 62)

        try FileManager.default.removeItem(at: url)
        XCTAssertNil(MusicXMLParser.loadScore(item: item))
    }

    func testMalformedXMLIsRejected() {
        XCTAssertNil(MusicXMLParser.parse(data: Data("<score-partwise><part>".utf8)))
    }
}
