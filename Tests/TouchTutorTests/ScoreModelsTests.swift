import Foundation
import Testing
@testable import TouchTutor

struct ScoreModelsTests {

  // MARK: - ScorePitch midiNote

  @Test(arguments: [
    ("C", 0, 4, 60),
    ("D", 0, 4, 62),
    ("E", 0, 4, 64),
    ("F", 0, 4, 65),
    ("G", 0, 4, 67),
    ("A", 0, 4, 69),
    ("B", 0, 4, 71),
    ("C", 0, 3, 48),
    ("C", 0, 5, 72),
  ])
  func midiNoteNaturalNotes(step: String, alter: Int, octave: Int, expected: UInt8) {
    let pitch = ScorePitch(step: step, alter: alter, octave: octave)
    #expect(pitch.midiNote == expected)
  }

  @Test func midiNoteSharps() {
    #expect(ScorePitch(step: "C", alter: 1, octave: 4).midiNote == 61)
    #expect(ScorePitch(step: "D", alter: 1, octave: 4).midiNote == 63)
    #expect(ScorePitch(step: "F", alter: 1, octave: 4).midiNote == 66)
    #expect(ScorePitch(step: "G", alter: 1, octave: 4).midiNote == 68)
    #expect(ScorePitch(step: "A", alter: 1, octave: 4).midiNote == 70)
  }

  @Test func midiNoteFlats() {
    #expect(ScorePitch(step: "D", alter: -1, octave: 4).midiNote == 61)
    #expect(ScorePitch(step: "B", alter: -1, octave: 3).midiNote == 58)
  }

  @Test func midiNoteDoubleAccidentals() {
    #expect(ScorePitch(step: "E", alter: -1, octave: 4).midiNote == 63)
  }

  @Test func midiNoteClampsToRange() {
    let low = ScorePitch(step: "C", alter: -100, octave: 0)
    #expect(low.midiNote == 0)

    let high = ScorePitch(step: "B", alter: 100, octave: 10)
    #expect(high.midiNote == 127)
  }

  @Test func midiNoteCaseInsensitive() {
    let lower = ScorePitch(step: "c", alter: 0, octave: 4)
    let upper = ScorePitch(step: "C", alter: 0, octave: 4)
    #expect(lower.midiNote == upper.midiNote)
  }

  // MARK: - ScorePitch displayName

  @Test func displayNameNaturalNote() {
    let pitch = ScorePitch(step: "C", alter: 0, octave: 4)
    #expect(pitch.displayName == "C4")
  }

  @Test func displayNameSharp() {
    let pitch = ScorePitch(step: "F", alter: 1, octave: 4)
    #expect(pitch.displayName == "F♯4")
  }

  @Test func displayNameFlat() {
    let pitch = ScorePitch(step: "B", alter: -1, octave: 3)
    #expect(pitch.displayName == "B♭3")
  }

  @Test func displayNameDoubleSharp() {
    let pitch = ScorePitch(step: "F", alter: 2, octave: 4)
    #expect(pitch.displayName == "F♯♯4")
  }

  @Test func displayNameDoubleFlat() {
    let pitch = ScorePitch(step: "B", alter: -2, octave: 4)
    #expect(pitch.displayName == "B♭♭4")
  }

  // MARK: - NoteValueType from xmlType

  @Test(arguments: [
    ("whole", NoteValueType.whole),
    ("half", NoteValueType.half),
    ("quarter", NoteValueType.quarter),
    ("eighth", NoteValueType.eighth),
    ("16th", NoteValueType.sixteenth),
    ("sixteenth", NoteValueType.sixteenth),
    ("32nd", NoteValueType.thirtySecond),
    ("thirtysecond", NoteValueType.thirtySecond),
    ("thirty-second", NoteValueType.thirtySecond),
    ("64th", NoteValueType.sixtyFourth),
    ("sixtyfourth", NoteValueType.sixtyFourth),
    ("sixty-fourth", NoteValueType.sixtyFourth),
    ("long", NoteValueType.breve),
    ("maxima", NoteValueType.breve),
    (" Whole ", NoteValueType.whole),
    ("QUARTER", NoteValueType.quarter),
    ("unknown", nil as NoteValueType?),
  ])
  func noteValueTypeFromXMLType(_ xmlType: String, expected: NoteValueType?) {
    #expect(NoteValueType.from(xmlType: xmlType) == expected)
  }

  // MARK: - NoteValueType from divisions

  @Test func noteValueTypeFromDivisions_breve() {
    // quarterFraction >= 6.0 → breve
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 24) == .breve)  // 24/4 = 6.0
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 30) == .breve)  // 30/4 = 7.5
  }

  @Test func noteValueTypeFromDivisions_whole() {
    // quarterFraction >= 3.0 and < 6.0 → whole
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 12) == .whole)  // 12/4 = 3.0
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 16) == .whole)  // 16/4 = 4.0
  }

  @Test func noteValueTypeFromDivisions_half() {
    // quarterFraction >= 1.5 and < 3.0 → half
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 6) == .half)    // 6/4 = 1.5
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 8) == .half)    // 8/4 = 2.0
  }

  @Test func noteValueTypeFromDivisions_quarter() {
    // quarterFraction >= 0.75 and < 1.5 → quarter
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 3) == .quarter)  // 3/4 = 0.75
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 4) == .quarter)  // 4/4 = 1.0
  }

  @Test func noteValueTypeFromDivisions_eighthAndShorter() {
    // quarterFraction >= 0.375 and < 0.75 → eighth
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 2) == .eighth)    // 2/4 = 0.5
    // quarterFraction >= 0.1875 and < 0.375 → sixteenth
    #expect(NoteValueType.from(divisions: 4, durationInDivisions: 1) == .sixteenth) // 1/4 = 0.25
    // < 0.1875 → thirtySecond (or lower)
    #expect(NoteValueType.from(divisions: 8, durationInDivisions: 1) == .thirtySecond) // 1/8 = 0.125
  }

  // MARK: - NoteValueType properties

  @Test func noteValueTypeFlagsCount() {
    #expect(NoteValueType.breve.flagsCount == 0)
    #expect(NoteValueType.whole.flagsCount == 0)
    #expect(NoteValueType.half.flagsCount == 0)
    #expect(NoteValueType.quarter.flagsCount == 0)
    #expect(NoteValueType.eighth.flagsCount == 1)
    #expect(NoteValueType.sixteenth.flagsCount == 2)
    #expect(NoteValueType.thirtySecond.flagsCount == 3)
    #expect(NoteValueType.sixtyFourth.flagsCount == 4)
  }

  @Test func noteValueTypeHasStem() {
    #expect(!NoteValueType.breve.hasStem)
    #expect(!NoteValueType.whole.hasStem)
    #expect(NoteValueType.half.hasStem)
    #expect(NoteValueType.quarter.hasStem)
    #expect(NoteValueType.eighth.hasStem)
  }

  @Test func noteValueTypeIsHollow() {
    #expect(NoteValueType.breve.isHollow)
    #expect(NoteValueType.whole.isHollow)
    #expect(NoteValueType.half.isHollow)
    #expect(!NoteValueType.quarter.isHollow)
    #expect(!NoteValueType.eighth.isHollow)
  }

  // MARK: - TempoAdjustment

  @Test func tempoAdjustmentDurationMultiplier() {
    #expect(TempoAdjustment.long.durationMultiplier == 1.5)
    #expect(TempoAdjustment.normal.durationMultiplier == 1.0)
    #expect(TempoAdjustment.fast.durationMultiplier == 0.67)
  }

  @Test func tempoAdjustmentIDs() {
    #expect(TempoAdjustment.long.id == "long")
    #expect(TempoAdjustment.normal.id == "normal")
    #expect(TempoAdjustment.fast.id == "fast")
  }

  @Test func tempoAdjustmentCaseIterable() {
    #expect(Array(TempoAdjustment.allCases).count == 3)
  }

  // MARK: - ScoreItem

  @Test func scoreItemDefaultScoresContainsTestInDebug() {
    #if DEBUG
      #expect(ScoreItem.defaultScores.contains { $0.id == "test" })
    #else
      #expect(!ScoreItem.defaultScores.contains { $0.id == "test" })
    #endif
  }

  @Test func scoreItemDefaultScoresContainsZanarkand() {
    #expect(ScoreItem.defaultScores.contains { $0.id == "zanarkand" })
  }

  @Test func scoreItemHashable() {
    let a = ScoreItem(id: "x", name: "X", filename: "x.xml", defaultTitle: "X", defaultArtist: "A", defaultAlbum: "Alb")
    let b = ScoreItem(id: "x", name: "X", filename: "x.xml", defaultTitle: "X", defaultArtist: "A", defaultAlbum: "Alb")
    let c = ScoreItem(id: "y", name: "Y", filename: "y.xml", defaultTitle: "Y", defaultArtist: "B", defaultAlbum: "Alb2")
    #expect(a == b)
    #expect(a != c)
    var set: Set<ScoreItem> = []
    set.insert(a)
    set.insert(b)
    set.insert(c)
    #expect(set.count == 2)
  }

  @Test func scoreItemIdentifiable() {
    let item = ScoreItem(id: "unique-1", name: "Test", filename: "test.xml", defaultTitle: "Test", defaultArtist: "Artist", defaultAlbum: "Album")
    #expect(item.id == "unique-1")
  }

  // MARK: - ScoreStep

  @Test func scoreStepEquatable() {
    let a = ScoreStep(id: 0, measureNumber: 1, onset: 0, notes: [], durationSeconds: 1.0,
                      noteValueType: .quarter, isDotted: false)
    let b = ScoreStep(id: 0, measureNumber: 1, onset: 0, notes: [], durationSeconds: 1.0,
                      noteValueType: .quarter, isDotted: false)
    let c = ScoreStep(id: 1, measureNumber: 2, onset: 4, notes: [], durationSeconds: 0.5,
                      noteValueType: .eighth, isDotted: false)
    #expect(a == b)
    #expect(a != c)
  }

  // MARK: - ParsedScore

  @Test func parsedScoreEquatable() {
    let a = ParsedScore(title: "Test", artist: "Artist", album: "Album", steps: [])
    let b = ParsedScore(title: "Test", artist: "Artist", album: "Album", steps: [])
    let c = ParsedScore(title: "Other", artist: "Artist", album: "Album", steps: [])
    #expect(a == b)
    #expect(a != c)
  }
}
