import Foundation

struct ImportedScoreLibrary {
  private struct Record: Codable {
    let id: UUID
    let name: String
    let artist: String
    let album: String

    var filename: String { "\(id.uuidString).xml" }
  }

  let directory: URL

  init(
    directory: URL = URL.applicationSupportDirectory
      .appendingPathComponent("TouchTutor/ImportedScores", isDirectory: true)
  ) {
    self.directory = directory
  }

  func loadScores() throws -> [ScoreItem] {
    try readRecords().compactMap { record in
      guard FileManager.default.fileExists(atPath: fileURL(for: record).path) else { return nil }
      return item(for: record)
    }
  }

  func importScore(from source: URL) throws -> (item: ScoreItem, score: ParsedScore) {
    let hasAccess = source.startAccessingSecurityScopedResource()
    defer { if hasAccess { source.stopAccessingSecurityScopedResource() } }
    let data = try Data(contentsOf: source)
    let name = source.deletingPathExtension().lastPathComponent
    guard let parsed = MusicXMLParser.parse(data: data, defaultTitle: name),
      !parsed.steps.isEmpty
    else {
      throw CocoaError(.fileReadCorruptFile)
    }

    var records = try readRecords()
    if let existing = records.first(where: { (try? Data(contentsOf: fileURL(for: $0))) == data }) {
      return (item(for: existing), parsed)
    }

    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let record = Record(id: UUID(), name: parsed.title, artist: parsed.artist, album: parsed.album)
    let destination = fileURL(for: record)
    try data.write(to: destination, options: .atomic)
    records.append(record)
    do {
      try save(records)
    } catch {
      try? FileManager.default.removeItem(at: destination)
      throw error
    }
    return (item(for: record), parsed)
  }

  func deleteScore(_ item: ScoreItem) throws {
    guard item.isImported else { return }
    var records = try readRecords()
    guard let index = records.firstIndex(where: { $0.id.uuidString == item.id }) else { return }
    let record = records.remove(at: index)
    try save(records)
    try? FileManager.default.removeItem(at: fileURL(for: record))
  }

  private var indexURL: URL { directory.appendingPathComponent("library.json") }

  private func readRecords() throws -> [Record] {
    guard FileManager.default.fileExists(atPath: indexURL.path) else { return [] }
    return try JSONDecoder().decode([Record].self, from: Data(contentsOf: indexURL))
  }

  private func save(_ records: [Record]) throws {
    try JSONEncoder().encode(records).write(to: indexURL, options: .atomic)
  }

  private func fileURL(for record: Record) -> URL {
    directory.appendingPathComponent(record.filename)
  }

  private func item(for record: Record) -> ScoreItem {
    ScoreItem(
      id: record.id.uuidString, name: record.name, filename: record.filename,
      defaultTitle: record.name, defaultArtist: record.artist, defaultAlbum: record.album,
      isImported: true, importedFileURL: fileURL(for: record))
  }
}
