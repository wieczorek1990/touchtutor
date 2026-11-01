import Foundation
import Testing
@testable import TouchTutor

struct MusicXMLParserTests {
    @Test func chordsAreSortedDeduplicatedAndDoNotAdvanceTheNextNote() throws {
        let score = try parse("""
        <measure number="1">
            <attributes><divisions>4</divisions></attributes>
            <note><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration></note>
            <note><chord/><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
            <note><chord/><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration></note>
            <note><pitch><step>D</step><octave>4</octave></pitch><duration>4</duration></note>
        </measure>
        """)

        #expect(score.steps.map(\.onset) == [0, 4])
        #expect(score.steps.map(\.id) == [0, 1])
        #expect(score.steps.map { $0.notes.map(\.midiNote) } == [[60, 67], [62]])
    }

    @Test func backupMergesVoicesAndPreservesTheLongestMeasure() throws {
        let score = try parse("""
        <measure number="7">
            <attributes><divisions>4</divisions></attributes>
            <note><pitch><step>C</step><octave>4</octave></pitch><duration>8</duration></note>
            <backup><duration>8</duration></backup>
            <note><pitch><step>E</step><octave>4</octave></pitch><duration>4</duration></note>
        </measure>
        <measure number="8">
            <note><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration></note>
        </measure>
        """)

        #expect(score.steps.map(\.onset) == [0, 8])
        #expect(score.steps.map(\.measureNumber) == [7, 8])
        #expect(score.steps.map { $0.notes.map(\.midiNote) } == [[60, 64], [67]])
        #expect(score.steps.map(\.durationSeconds) == [1.5, 0.75])
    }

    @Test func restsAndForwardMoveTheTimelineWithoutCreatingSteps() throws {
        let score = try parse("""
        <measure number="1">
            <attributes><divisions>4</divisions></attributes>
            <note><rest/><duration>4</duration></note>
            <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
            <forward><duration>4</duration></forward>
        </measure>
        <measure number="2">
            <note><pitch><step>D</step><octave>4</octave></pitch><duration>4</duration></note>
        </measure>
        """)

        #expect(score.steps.map(\.onset) == [4, 12])
        #expect(score.steps.map(\.measureNumber) == [1, 2])
        #expect(score.steps.map(\.durationSeconds) == [1.5, 0.75])
    }

    @Test(arguments: [
        ("<sound tempo=\"120\"/>", 4, 0.5),
        ("<metronome><per-minute>120</per-minute></metronome>", 4, 0.5),
        ("<sound tempo=\"120\"/>", 1, 0.35),
        ("<sound tempo=\"120\"/>", 32, 2.5),
        ("<sound tempo=\"0\"/>", 4, 0.75)
    ])
    func tempoConvertsDurationsAndAppliesPlaybackLimits(
        direction: String, duration: Int, expectedSeconds: Double
    ) throws {
        let score = try parse("""
        <measure number="1">
            <attributes><divisions>4</divisions></attributes>
            <direction>\(direction)</direction>
            <note><pitch><step>A</step><octave>4</octave></pitch><duration>\(duration)</duration></note>
        </measure>
        """)

        let step = try #require(score.steps.first)
        #expect(abs(step.durationSeconds - expectedSeconds) < 0.000001)
    }

    @Test func explicitDottedTypeAndAccidentalArePreserved() throws {
        let score = try parse("""
        <measure number="1">
            <attributes><divisions>4</divisions></attributes>
            <note>
                <pitch><step>B</step><alter>-1</alter><octave>3</octave></pitch>
                <duration>6</duration><type>quarter</type><dot/>
            </note>
        </measure>
        """)

        let step = try #require(score.steps.first)
        #expect(step.noteValueType == .quarter)
        #expect(step.isDotted)
        #expect(step.notes == [ScorePitch(step: "B", alter: -1, octave: 3)])
        #expect(step.notes.first?.midiNote == 58)
        #expect(step.durationSeconds == 1.125)
    }

    @Test func missingTypeIsInferredFromDuration() throws {
        let score = try parse("""
        <measure number="1">
            <attributes><divisions>4</divisions></attributes>
            <note><pitch><step>C</step><octave>4</octave></pitch><duration>2</duration></note>
        </measure>
        """)

        let step = try #require(score.steps.first)
        #expect(step.noteValueType == .eighth)
        #expect(!step.isDotted)
    }

    @Test(arguments: [
        ("", "Fallback"),
        ("<work><work-title>   </work-title></work>", "Fallback"),
        ("<movement-title>Movement</movement-title>", "Movement"),
        ("<work><work-title>  Work &amp; Title  </work-title></work><movement-title>Movement</movement-title>", "Work & Title")
    ])
    func titlesUseMetadataOrTheProvidedFallback(metadata: String, expected: String) throws {
        let xml = "<score-partwise>\(metadata)<part><measure number=\"1\"/></part></score-partwise>"
        let score = try #require(MusicXMLParser.parse(data: Data(xml.utf8), defaultTitle: "Fallback"))

        #expect(score.title == expected)
        #expect(score.steps.isEmpty)
    }

    private func parse(_ measures: String) throws -> ParsedScore {
        let xml = "<score-partwise><part>\(measures)</part></score-partwise>"
        return try #require(MusicXMLParser.parse(data: Data(xml.utf8)))
    }
}
