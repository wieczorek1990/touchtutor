import Foundation

struct ScoreItem: Identifiable, Hashable {
  let id: String
  let title: String
  let filename: String
  let artist: String
  let album: String
  var isImported: Bool = false
  var importedFileURL: URL?
  var requiredProductID: String?

  static let defaultScores: [ScoreItem] = {
    var scores = loadScoresFromTOML("scores_free")
    #if DEBUG
      let testScores = loadScoresFromTOML("scores_test")
      scores.insert(contentsOf: testScores, at: 0)
    #endif
    return scores
  }()

  private static func loadScoresFromTOML(_ name: String) -> [ScoreItem] {
    guard let toml = TOMLParser.loadResource(name) else { return [] }
    let tables = TOMLParser.parse(toml)
    var scores: [ScoreItem] = []
    for table in tables {
      // Each table may be a wrapper containing a "scores" array, or a direct score entry
      if let scoresArray = table["scores"] as? [[String: Any]] {
        for entry in scoresArray {
          if let item = ScoreItem.fromTOML(entry) {
            scores.append(item)
          }
        }
      } else if let item = ScoreItem.fromTOML(table) {
        scores.append(item)
      }
    }
    return scores
  }

  /// Create a ScoreItem from a TOML table entry.
  static func fromTOML(_ table: [String: Any]) -> ScoreItem? {
    guard let id = table["id"] as? String else { return nil }
    let title = (table["title"] as? String) ?? id
    let artist = table["artist"] as? String ?? ""
    let album = table["album"] as? String ?? ""
    return ScoreItem(
      id: id,
      title: L10n.string(title),
      filename: id + ".xml",
      artist: L10n.string(artist),
      album: L10n.string(album)
    )
  }
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

enum SoundFont: Int, CaseIterable, Identifiable {
  case piano
  case electricGuitar

  var id: Int { rawValue }

  var displayName: String {
    switch self {
    case .piano: return L10n.string("Piano")
    case .electricGuitar: return L10n.string("E. Guitar")
    }
  }

  /// MIDI program number (GM/GS bank 0).
  var program: UInt8 {
    switch self {
    case .piano: return 0  // Acoustic Grand Piano
    case .electricGuitar: return 27  // Steel String Electric Guitar
    }
  }
}

struct ParsedScore: Equatable {
  let title: String
  let artist: String
  let album: String
  let steps: [ScoreStep]
  let voices: [String]
}
