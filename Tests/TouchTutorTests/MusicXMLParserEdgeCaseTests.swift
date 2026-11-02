import Foundation
import Testing
@testable import TouchTutor

struct MusicXMLParserEdgeCaseTests {

  private func parse(_ measures: String) throws -> ParsedScore {
    let xml = "<score-partwise><part>\(measures)</part></score-partwise>"
    return try #require(MusicXMLParser.parse(data: Data(xml.utf8)))
  }

  // MARK: - Empty and minimal scores

  @Test func emptyScoreHasNoSteps() throws {
    let score = try parse("<measure number=\"1\"/>")
    #expect(score.steps.isEmpty)
    #expect(score.title == "To Zanarkand")
  }

  @Test func emptyScoreUsesDefaultTitle() throws {
    let xml = "<score-partwise><part><measure number=\"1\"/></part></score-partwise>"
    let score = try #require(MusicXMLParser.parse(data: Data(xml.utf8), defaultTitle: "My Score"))
    #expect(score.title == "My Score")
  }

  @Test func scoreWithOnlyRestsHasNoSteps() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><rest/><duration>4</duration></note>
      <note><rest/><duration>4</duration></note>
    </measure>
    """)
    #expect(score.steps.isEmpty)
  }

  // MARK: - Multiple measures

  @Test func multipleMeasuresPreserveMeasureNumbers() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    <measure number="2">
      <note><pitch><step>D</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    <measure number="3">
      <note><pitch><step>E</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    #expect(score.steps.count == 3)
    #expect(score.steps.map(\.measureNumber) == [1, 2, 3])
  }

  @Test func measureGapsAreHandledCorrectly() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    <measure number="5">
      <note><pitch><step>D</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    #expect(score.steps.count == 2)
    #expect(score.steps.map(\.measureNumber) == [1, 5])
  }

  // MARK: - Chords

  @Test func chordPitchesAreSortedByMidiNote() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>E</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><chord/><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><chord/><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    #expect(step.notes.map(\.midiNote) == [60, 64, 67])
  }

  @Test func duplicateChordPitchIsDeduplicated() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><chord/><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    #expect(step.notes.count == 1)
  }

  @Test func multiChordProgression() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><chord/><pitch><step>E</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><pitch><step>F</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><chord/><pitch><step>A</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><chord/><pitch><step>B</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    #expect(score.steps.count == 3)
    #expect(score.steps[0].notes.map(\.midiNote) == [60, 64])
    #expect(score.steps[1].notes.map(\.midiNote) == [65, 69])
    #expect(score.steps[2].notes.map(\.midiNote) == [67, 71])
  }

  // MARK: - Tempo changes

  @Test func tempoChangeMidScore() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <sound tempo="120"/>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    <measure number="2">
      <sound tempo="60"/>
      <note><pitch><step>D</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    #expect(score.steps.count == 2)
    // Duration is determined by gap to next step: step 0 onset=0, step 1 onset=4+4=8
    // durationInDivs = 8-0 = 8; rawSeconds = (8/4) * (60/120) = 2 * 0.5 = 1.0
    #expect(score.steps[0].durationSeconds == 1.0)
    // Last step: uses its own note duration; tempo=60 BPM
    // rawSeconds = (4/4) * (60/60) = 1.0
    #expect(score.steps[1].durationSeconds == 1.0)
  }

  @Test func zeroTempoUsesDefault() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <sound tempo="0"/>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    // tempo=0 falls back to 80 BPM; duration clamped to 0.75
    #expect(step.durationSeconds == 0.75)
  }

  // MARK: - Note range boundaries

  @Test func lowMidiNotes() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>A</step><octave>0</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    #expect(step.notes.first?.midiNote == 21)  // A0 = MIDI 21
  }

  @Test func highMidiNotes() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>C</step><octave>8</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    #expect(step.notes.first?.midiNote == 108)  // C8 = MIDI 108
  }

  // MARK: - Dotted notes

  @Test func multipleDots() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note>
        <pitch><step>C</step><octave>4</octave></pitch>
        <duration>4</duration><type>quarter</type><dot/><dot/>
      </note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    #expect(step.isDotted)
    #expect(step.noteValueType == .quarter)
  }

  // MARK: - Backup and forward

  @Test func forwardAloneAdvancesTimeline() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <forward><duration>4</duration></forward>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    #expect(step.onset == 4)
  }

  @Test func backupFollowedByNote() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>8</duration></note>
      <backup><duration>8</duration></backup>
      <note><pitch><step>D</step><octave>4</octave></pitch><duration>4</duration></note>
      <note><pitch><step>E</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    // C4 at onset 0, then backup 8 back; D4 at onset 0 (merged with C4), E4 at onset 4
    #expect(score.steps.count == 2)
    #expect(score.steps[0].notes.map(\.midiNote) == [60, 62])  // C4 + D4 at onset 0
    #expect(score.steps[1].notes.map(\.midiNote) == [64])        // E4 at onset 4
  }

  // MARK: - Duration clamping

  @Test func veryLongDurationIsClamped() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>1</divisions></attributes>
      <sound tempo="120"/>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>100</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    #expect(step.durationSeconds <= 2.5)
  }

  @Test func veryShortDurationIsClamped() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>64</divisions></attributes>
      <sound tempo="200"/>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>1</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    #expect(step.durationSeconds >= 0.35)
  }

  // MARK: - Title metadata

  @Test func movementTitleTakesPrecedence() throws {
    let xml = """
    <score-partwise>
      <movement-title>Movement</movement-title>
      <work><work-title>Work</work-title></work>
      <part><measure number="1"/></part>
    </score-partwise>
    """
    let score = try #require(MusicXMLParser.parse(data: Data(xml.utf8)))
    #expect(score.title == "Movement")
  }

  @Test func workTitleUsedWhenNoMovementTitle() throws {
    let xml = """
    <score-partwise>
      <work><work-title>Work Title</work-title></work>
      <part><measure number="1"/></part>
    </score-partwise>
    """
    let score = try #require(MusicXMLParser.parse(data: Data(xml.utf8)))
    #expect(score.title == "Work Title")
  }

  @Test func whitespaceOnlyTitleUsesFallback() throws {
    let xml = """
    <score-partwise>
      <work><work-title>   </work-title></work>
      <part><measure number="1"/></part>
    </score-partwise>
    """
    let score = try #require(MusicXMLParser.parse(data: Data(xml.utf8), defaultTitle: "Fallback"))
    #expect(score.title == "Fallback")
  }

  // MARK: - XML special characters

  @Test func xmlEntityInTitle() throws {
    let xml = "<score-partwise><work><work-title>A &amp; B</work-title></work><part><measure number=\"1\"/></part></score-partwise>"
    let score = try #require(MusicXMLParser.parse(data: Data(xml.utf8)))
    #expect(score.title == "A & B")
  }

  // MARK: - Malformed XML

  @Test func completelyInvalidXML() {
    #expect(MusicXMLParser.parse(data: Data("not xml at all".utf8)) == nil)
  }

  @Test func unclosedTags() {
    #expect(MusicXMLParser.parse(data: Data("<score-partwise><part>".utf8)) == nil)
  }

  @Test func emptyData() {
    #expect(MusicXMLParser.parse(data: Data()) == nil)
  }

  // MARK: - Metronome tag

  @Test func metronomeTagSetsTempo() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <metronome><per-minute>120</per-minute></metronome>
      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    let step = try #require(score.steps.first)
    // 120 BPM, 1 quarter note = 0.5s
    #expect(step.durationSeconds == 0.5)
  }

  // MARK: - Alter values

  @Test func positiveAndNegativeAlter() throws {
    let score = try parse("""
    <measure number="1">
      <attributes><divisions>4</divisions></attributes>
      <note><pitch><step>F</step><alter>1</alter><octave>4</octave></pitch><duration>4</duration></note>
      <note><pitch><step>F</step><alter>-1</alter><octave>4</octave></pitch><duration>4</duration></note>
    </measure>
    """)
    #expect(score.steps.count == 2)
    #expect(score.steps[0].notes.first?.midiNote == 66)  // F#4
    #expect(score.steps[1].notes.first?.midiNote == 64)  // Fb4 = E4 = MIDI 64
  }

  // MARK: - Multi-part scores

  @Test func multiPartScoreMergesNotesCorrectly() throws {
    // Two parts with notes at the same onset should be merged into one step
    let xml = """
    <score-partwise>
      <part id="P1">
        <measure number="1">
          <attributes><divisions>4</divisions></attributes>
          <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
        </measure>
        <measure number="2">
          <note><pitch><step>D</step><octave>4</octave></pitch><duration>4</duration></note>
        </measure>
      </part>
      <part id="P2">
        <measure number="1">
          <attributes><divisions>4</divisions></attributes>
          <note><pitch><step>G</step><octave>3</octave></pitch><duration>4</duration></note>
        </measure>
        <measure number="2">
          <note><pitch><step>A</step><octave>3</octave></pitch><duration>4</duration></note>
        </measure>
      </part>
    </score-partwise>
    """
    let score = try #require(MusicXMLParser.parse(data: Data(xml.utf8)))
    #expect(score.steps.count == 2)
    // Part 1 C4 (60) + Part 2 G3 (55) at onset 0
    #expect(score.steps[0].notes.map(\.midiNote) == [55, 60])
    // Part 1 D4 (62) + Part 2 A3 (57) at onset 4
    #expect(score.steps[1].notes.map(\.midiNote) == [57, 62])
  }

  @Test func multiPartScoreResetsMeasureTracking() throws {
    // Ensure Part 2 doesn't have measureAbsoluteStart offset from Part 1
    let xml = """
    <score-partwise>
      <part id="P1">
        <measure number="1">
          <attributes><divisions>4</divisions></attributes>
          <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration></note>
        </measure>
      </part>
      <part id="P2">
        <measure number="1">
          <attributes><divisions>4</divisions></attributes>
          <note><pitch><step>G</step><octave>3</octave></pitch><duration>4</duration></note>
        </measure>
      </part>
    </score-partwise>
    """
    let score = try #require(MusicXMLParser.parse(data: Data(xml.utf8)))
    // Both notes should be merged at onset 0, not separated by Part 1's duration
    #expect(score.steps.count == 1)
    #expect(score.steps[0].onset == 0)
    #expect(score.steps[0].notes.map(\.midiNote) == [55, 60])
  }
}
