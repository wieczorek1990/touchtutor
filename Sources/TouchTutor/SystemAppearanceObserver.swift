import Combine
import SwiftUI

#if os(macOS)
  @MainActor
  final class SystemAppearanceObserver: ObservableObject {
    @Published private(set) var colorScheme: ColorScheme =
      UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? .dark : .light

    private var appearanceSubscription: AnyCancellable?

    init() {
      appearanceSubscription = DistributedNotificationCenter.default()
        .publisher(for: Notification.Name("AppleInterfaceThemeChangedNotification"))
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
          self?.colorScheme =
            UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? .dark : .light
        }
    }
  }
#endif
