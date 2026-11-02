import Foundation

/// Minimal TOML parser that handles the subset used by score configuration files:
/// - `[[array_of_tables]]` entries
/// - `key = "value"` string pairs (including nested `[[array.table]]`)
/// - Comments and blank lines
struct TOMLParser {
  /// Parse a TOML string into an array of top-level tables.
  /// Supports `[[section]]` array-of-tables and nested `[[section.sub]]`.
  static func parse(_ input: String) -> [[String: Any]] {
    let lines = input.components(separatedBy: .newlines)

    // State: we track the current top-level array key (e.g. "scores" or "packs")
    // and optionally a nested array key (e.g. "scores" inside [[packs.scores]])
    var result: [[String: Any]] = []
    var currentTable: [String: Any] = [:]
    var topLevelKey: String? = nil       // e.g. "scores" from [[scores]]
    var nestedKey: String? = nil         // e.g. "scores" from [[packs.scores]]
    var nestedEntries: [[String: Any]] = []
    var nestedEntry: [String: Any] = [:]

    func flushNestedEntry() {
      if !nestedEntry.isEmpty {
        nestedEntries.append(nestedEntry)
        nestedEntry = [:]
      }
    }

    func flushNested() {
      if let key = nestedKey {
        flushNestedEntry()
        currentTable[key] = nestedEntries
        nestedEntries = []
        nestedKey = nil
      }
    }

    func flushTable() {
      flushNested()
      if !currentTable.isEmpty {
        result.append(currentTable)
      }
      currentTable = [:]
      topLevelKey = nil
    }

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

      // Array of tables: [[key]] or [[key.sub]]
      if trimmed.hasPrefix("[[") && trimmed.hasSuffix("]]") {
        let header = trimmed.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespaces)

        if let dotRange = header.range(of: ".") {
          // Nested: [[parent.child]]
          let parent = String(header[..<dotRange.lowerBound]).trimmingCharacters(in: .whitespaces)
          let child = String(header[dotRange.upperBound...]).trimmingCharacters(in: .whitespaces)

          // If we're in a different top-level context, flush first
          if topLevelKey != parent {
            flushTable()
          }

          // Save the previous nested entry before starting a new one
          // (but don't flush the whole nested array yet — keep accumulating)
          if nestedKey == child {
            flushNestedEntry()
          } else {
            flushNested()
          }

          topLevelKey = parent
          nestedKey = child
          if nestedKey == child && topLevelKey == parent {
            // Same nested key within same parent: keep accumulating
            // nestedEntries already has previous entries
          } else {
            nestedEntries = []
          }
          nestedEntry = [:]
        } else {
          // Top-level: [[key]]
          flushTable()
          topLevelKey = header
        }
        continue
      }

      // Key = value
      if let eqRange = trimmed.range(of: " = ") {
        let key = trimmed[..<eqRange.lowerBound].trimmingCharacters(in: .whitespaces)
        let valueStr = trimmed[eqRange.upperBound...].trimmingCharacters(in: .whitespaces)
        let value = parseValue(valueStr)

        if nestedKey != nil {
          nestedEntry[key] = value
        } else {
          currentTable[key] = value
        }
      }
    }

    // Final flush
    flushTable()

    return result
  }

  private static func parseValue(_ str: String) -> Any {
    let trimmed = str.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
      return String(trimmed.dropFirst().dropLast())
    }
    if trimmed == "true" { return true }
    if trimmed == "false" { return false }
    if let int = Int(trimmed) { return int }
    if let double = Double(trimmed) { return double }
    return trimmed
  }
}

// MARK: - Convenience: load from bundle resource

extension TOMLParser {
  static func loadResource(_ name: String, bundle: Bundle = .module) -> String? {
    guard let url = bundle.url(forResource: name, withExtension: "toml")
      ?? Bundle.main.url(forResource: name, withExtension: "toml")
    else { return nil }
    return try? String(contentsOf: url, encoding: .utf8)
  }
}
