import Foundation

enum L10n {
  static func string(_ key: String) -> String {
    Bundle.module.localizedString(forKey: key, value: key, table: nil)
  }

  static func format(_ key: String, _ args: CVarArg...) -> String {
    String(format: string(key), locale: Locale.current, arguments: args)
  }
}

#if !SWIFT_PACKAGE
  extension Bundle {
    static let module = Bundle.main
  }
#endif
