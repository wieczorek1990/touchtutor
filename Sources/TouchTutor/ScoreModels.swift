import Foundation

struct ScoreItem: Identifiable, Hashable {
  let id: String
  let name: String
  let filename: String
  let defaultTitle: String
  let defaultArtist: String
  let defaultAlbum: String
  var isImported: Bool = false
  var importedFileURL: URL?
  var requiredProductID: String?

  static let defaultScores: [ScoreItem] = {
    var scores = [
      ScoreItem(
        id: "zanarkand",
        name: L10n.string("To Zanarkand (Final Fantasy X)"),
        filename: "Nobuo Uematsu - To Zanarkand.xml",
        defaultTitle: L10n.string("To Zanarkand"),
        defaultArtist: L10n.string("Nobuo Uematsu"),
        defaultAlbum: L10n.string("Final Fantasy X")
      ),
      ScoreItem(
        id: "eyes_on_me",
        name: L10n.string("Eyes On Me (Final Fantasy VIII)"),
        filename: "Nobuo Uematsu - Eyes on Me.xml",
        defaultTitle: L10n.string("Eyes on Me"),
        defaultArtist: L10n.string("Nobuo Uematsu"),
        defaultAlbum: L10n.string("Final Fantasy VIII")
      ),
      ScoreItem(
        id: "dancing_mad",
        name: L10n.string("Dancing Mad (Final Fantasy VI)"),
        filename: "Nobuo Uematsu - Dancing Mad.xml",
        defaultTitle: L10n.string("Dancing Mad"),
        defaultArtist: L10n.string("Nobuo Uematsu"),
        defaultAlbum: L10n.string("Final Fantasy VI")
      ),
    ]
    #if DEBUG
      scores.insert(
        ScoreItem(
          id: "test",
          name: L10n.string("Test"),
          filename: "Test.xml",
          defaultTitle: L10n.string("Test"),
          defaultArtist: L10n.string("Test Artist"),
          defaultAlbum: L10n.string("Test Album")
        ),
        at: 0
      )
      scores.insert(
        ScoreItem(
          id: "test_long_title",
          name: L10n.string(
            "Test with a Very Long Title That Should Be Exactly Eighty Eight Characters in Length Now"
          ),
          filename: "Test.xml",
          defaultTitle: L10n.string("Test Long Title"),
          defaultArtist: L10n.string("Test Artist"),
          defaultAlbum: L10n.string("Test Album")
        ),
        at: 1
      )
    #endif
    return scores
  }()
}

struct ScorePitch: Hashable {
  let step: String
  let alter: Int
  let octave: Int

  private static let stepOffsets: [String: Int] = [
    "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11,
  ]

  var midiNote: UInt8 {
    let base = ScorePitch.stepOffsets[step.uppercased()] ?? 0
    let val = (octave + 1) * 12 + base + alter
    return UInt8(clamping: max(0, min(127, val)))
  }

  var displayName: String {
    let alterStr = String(repeating: alter < 0 ? "♭" : "♯", count: abs(alter))
    return "\(step)\(alterStr)\(octave)"
  }
}

enum NoteValueType: String, CaseIterable, Equatable {
  case breve
  case whole
  case half
  case quarter
  case eighth
  case sixteenth = "16th"
  case thirtySecond = "32nd"
  case sixtyFourth = "64th"

  private static let noStemCases: Set<NoteValueType> = [.breve, .whole]
  private static let hollowCases: Set<NoteValueType> = [.breve, .whole, .half]

  var flagsCount: Int {
    switch self {
    case .eighth: return 1
    case .sixteenth: return 2
    case .thirtySecond: return 3
    case .sixtyFourth: return 4
    default: return 0
    }
  }

  var hasStem: Bool {
    !NoteValueType.noStemCases.contains(self)
  }

  var isHollow: Bool {
    NoteValueType.hollowCases.contains(self)
  }

  static func from(xmlType: String) -> NoteValueType? {
    let clean = xmlType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    switch clean {
    case "long", "maxima": return .breve
    case "sixteenth": return .sixteenth
    case "thirtysecond", "thirty-second": return .thirtySecond
    case "sixtyfourth", "sixty-fourth": return .sixtyFourth
    default: return NoteValueType(rawValue: clean)
    }
  }

  // Thresholds represent the fraction of a quarter note for each note value.
  // e.g., a half note = 0.5 quarter notes, an eighth = 0.25 quarter notes, etc.
  private static let noteValueThresholds: [(threshold: Double, value: NoteValueType)] = [
    (6.0, .breve),
    (3.0, .whole),
    (1.5, .half),
    (0.75, .quarter),
    (0.375, .eighth),
    (0.1875, .sixteenth),
    (0.09375, .thirtySecond),
  ]

  static func from(divisions: Int, durationInDivisions: Int) -> NoteValueType {
    guard divisions > 0 else { return .quarter }
    let quarterFraction = Double(durationInDivisions) / Double(divisions)
    for entry in noteValueThresholds {
      if quarterFraction >= entry.threshold {
        return entry.value
      }
    }
    return .sixtyFourth
  }
}
enum TempoAdjustment: String, CaseIterable, Identifiable {
  case long
  case normal
  case fast

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .long: return L10n.string("Long")
    case .normal: return L10n.string("Normal")
    case .fast: return L10n.string("Fast")
    }
  }

  var durationMultiplier: Double {
    switch self {
    case .long: return 1.5
    case .normal: return 1.0
    case .fast: return 0.67
    }
  }
}

struct ScoreStep: Identifiable, Equatable {
  let id: Int
  let measureNumber: Int
  let onset: Int
  let notes: [ScorePitch]
  let durationSeconds: Double
  let noteValueType: NoteValueType
  let isDotted: Bool
}

struct ParsedScore: Equatable {
  let title: String
  let artist: String
  let album: String
  let steps: [ScoreStep]
}
