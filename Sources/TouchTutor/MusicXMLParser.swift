import Foundation

final class MusicXMLParser: NSObject, XMLParserDelegate {
  private var currentText: String = ""

  private var workTitle: String = ""
  private var measureNumber: Int = 1
  private var currentDivisions: Int = 24
  private var currentTempo: Double = 80.0

  private var measureAbsoluteStart: Int = 0
  private var currentOffsetInMeasure: Int = 0
  private var lastNoteOffsetInMeasure: Int = 0
  private var maxMeasureDuration: Int = 0

  private var isNote: Bool = false
  private var isRest: Bool = false
  private var isChord: Bool = false
  private var isPitch: Bool = false
  private var isBackup: Bool = false
  private var isForward: Bool = false

  private var noteStep: String = ""
  private var noteAlter: Int = 0
  private var noteOctave: Int = 4
  private var noteDuration: Int = 0
  private var noteTypeString: String = ""
  private var noteDotsCount: Int = 0

  private var rawNotes:
    [(onset: Int, measure: Int, pitch: ScorePitch, duration: Int, type: String, dots: Int)] = []

  func parser(
    _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
  ) {
    currentText = ""

    switch elementName {
    case "measure":
      if let numStr = attributeDict["number"], let num = Int(numStr) {
        measureNumber = num
      }
      measureAbsoluteStart += maxMeasureDuration
      currentOffsetInMeasure = 0
      lastNoteOffsetInMeasure = 0
      maxMeasureDuration = 0
    case "sound":
      if let tempoStr = attributeDict["tempo"], let t = Double(tempoStr), t > 0 {
        currentTempo = t
      }
    case "note":
      isNote = true
      isRest = false
      isChord = false
      noteStep = ""
      noteAlter = 0
      noteOctave = 4
      noteDuration = 0
      noteTypeString = ""
      noteDotsCount = 0
    case "dot":
      if isNote {
        noteDotsCount += 1
      }
    case "rest":
      isRest = true
    case "chord":
      isChord = true
    case "pitch":
      isPitch = true
    case "backup":
      isBackup = true
      noteDuration = 0
    case "forward":
      isForward = true
      noteDuration = 0
    default:
      break
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    currentText += string
  }

  func parser(
    _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

    switch elementName {
    case "work-title", "movement-title":
      if !text.isEmpty && workTitle.isEmpty {
        workTitle = text
      }
    case "divisions":
      if let val = Int(text), val > 0 {
        currentDivisions = val
      }
    case "per-minute":
      if let val = Double(text), val > 0 {
        currentTempo = val
      }
    case "step":
      if isPitch { noteStep = text }
    case "alter":
      if isPitch, let val = Double(text) { noteAlter = Int(val) }
    case "octave":
      if isPitch, let val = Int(text) { noteOctave = val }
    case "type":
      if isNote { noteTypeString = text }
    case "duration":
      if let val = Int(text) {
        if isBackup || isForward || isNote {
          noteDuration = val
        }
      }
    case "pitch":
      isPitch = false
    case "backup":
      currentOffsetInMeasure = max(0, currentOffsetInMeasure - noteDuration)
      isBackup = false
    case "forward":
      currentOffsetInMeasure += noteDuration
      maxMeasureDuration = max(maxMeasureDuration, currentOffsetInMeasure)
      isForward = false
    case "note":
      let noteOnset: Int
      if isChord {
        noteOnset = measureAbsoluteStart + lastNoteOffsetInMeasure
      } else {
        noteOnset = measureAbsoluteStart + currentOffsetInMeasure
        lastNoteOffsetInMeasure = currentOffsetInMeasure
        currentOffsetInMeasure += noteDuration
        maxMeasureDuration = max(maxMeasureDuration, currentOffsetInMeasure)
      }

      if !isRest && !noteStep.isEmpty {
        let pitch = ScorePitch(step: noteStep, alter: noteAlter, octave: noteOctave)
        rawNotes.append(
          (
            onset: noteOnset, measure: measureNumber, pitch: pitch, duration: max(1, noteDuration),
            type: noteTypeString, dots: noteDotsCount
          ))
      }
      isNote = false
    default:
      break
    }
  }

  func buildScore(defaultTitle: String = "To Zanarkand") -> ParsedScore {
    struct RawGroup {
      var measure: Int
      var pitches: [ScorePitch]
      var maxDuration: Int
      var explicitType: String
      var dots: Int
    }
    var grouped: [Int: RawGroup] = [:]
    for item in rawNotes {
      if grouped[item.onset] == nil {
        grouped[item.onset] = RawGroup(
          measure: item.measure,
          pitches: [item.pitch],
          maxDuration: item.duration,
          explicitType: item.type,
          dots: item.dots
        )
      } else {
        if !grouped[item.onset]!.pitches.contains(item.pitch) {
          grouped[item.onset]!.pitches.append(item.pitch)
        }
        grouped[item.onset]!.maxDuration = max(grouped[item.onset]!.maxDuration, item.duration)
        if grouped[item.onset]!.explicitType.isEmpty && !item.type.isEmpty {
          grouped[item.onset]!.explicitType = item.type
          grouped[item.onset]!.dots = item.dots
        }
      }
    }

    let sortedOnsets = grouped.keys.sorted()
    var steps: [ScoreStep] = []
    let bpm = currentTempo > 0 ? currentTempo : 80.0
    let divs = currentDivisions > 0 ? currentDivisions : 24

    for (idx, onset) in sortedOnsets.enumerated() {
      guard let entry = grouped[onset] else { continue }
      let sortedPitches = entry.pitches.sorted { $0.midiNote < $1.midiNote }

      let durationInDivs: Int
      if idx + 1 < sortedOnsets.count {
        durationInDivs = max(1, sortedOnsets[idx + 1] - onset)
      } else {
        durationInDivs = max(1, entry.maxDuration)
      }

      let rawSeconds = (Double(durationInDivs) / Double(divs)) * (60.0 / bpm)
      let clampedDuration = max(0.35, min(2.5, rawSeconds))

      let resolvedType: NoteValueType
      if let parsed = NoteValueType.from(xmlType: entry.explicitType) {
        resolvedType = parsed
      } else {
        resolvedType = NoteValueType.from(divisions: divs, durationInDivisions: durationInDivs)
      }
      let isDotted = entry.dots > 0

      steps.append(
        ScoreStep(
          id: idx,
          measureNumber: entry.measure,
          onset: onset,
          notes: sortedPitches,
          durationSeconds: clampedDuration,
          noteValueType: resolvedType,
          isDotted: isDotted
        ))
    }

    let title = workTitle.isEmpty ? defaultTitle : workTitle
    return ParsedScore(title: title, steps: steps)
  }

  static func parse(data: Data, defaultTitle: String = "To Zanarkand") -> ParsedScore? {
    let parser = MusicXMLParser()
    let xmlParser = XMLParser(data: data)
    xmlParser.delegate = parser
    if xmlParser.parse() {
      return parser.buildScore(defaultTitle: defaultTitle)
    }
    return nil
  }

  static func loadScore(item: ScoreItem) -> ParsedScore? {
    if item.isImported {
      return loadScore(
        from: item.importedFileURL ?? URL(fileURLWithPath: item.id), defaultTitle: item.defaultTitle
      )
    }

    let baseName = (item.filename as NSString).deletingPathExtension
    let candidateURLs: [URL?] = [
      Bundle.module.url(forResource: baseName, withExtension: "xml"),
      Bundle.main.url(forResource: baseName, withExtension: "xml"),
      URL(fileURLWithPath: "Resources/Scores/\(item.filename)"),
    ]

    for case let url? in candidateURLs {
      if let score = loadScore(from: url, defaultTitle: item.defaultTitle) {
        return score
      }
    }
    return nil
  }

  static func loadScore(from url: URL, defaultTitle: String = L10n.string("Custom Score"))
    -> ParsedScore?
  {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return parse(data: data, defaultTitle: defaultTitle)
  }
}
