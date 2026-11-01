import SwiftUI

#if os(macOS)
  import AppKit

  @MainActor
  final class KeyboardMonitor {
    private var eventMonitor: Any?

    init(
      currentScreen: @escaping () -> AppScreen,
      isShowingStore: @escaping () -> Bool,
      isImportedSelected: @escaping () -> Bool,
      onAction: @escaping (KeyboardAction) -> Void
    ) {
      setupKeyMonitor(
        currentScreen: currentScreen,
        isShowingStore: isShowingStore,
        isImportedSelected: isImportedSelected,
        onAction: onAction
      )
    }

    func stop() {
      if let monitor = eventMonitor {
        NSEvent.removeMonitor(monitor)
        eventMonitor = nil
      }
    }

    private func setupKeyMonitor(
      currentScreen: @escaping () -> AppScreen,
      isShowingStore: @escaping () -> Bool,
      isImportedSelected: @escaping () -> Bool,
      onAction: @escaping (KeyboardAction) -> Void
    ) {
      eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        guard self != nil, !isShowingStore() else { return event }

        let isUnmodified = event.modifierFlags.intersection([.command, .control, .option]).isEmpty
        let isSpace = event.keyCode == 49 || event.charactersIgnoringModifiers == " "
        let isEnter =
          event.keyCode == 36 || event.keyCode == 76 || event.charactersIgnoringModifiers == "\r"
          || event.charactersIgnoringModifiers == "\n"
        let isDelete = event.keyCode == 51 || event.keyCode == 117
        let action: KeyboardAction?

        switch currentScreen() {
        case .menu:
          if event.keyCode == 53 {
            action = .exitApp
          } else if event.keyCode == 126 || event.keyCode == 123 {
            action = .selectPreviousScore
          } else if event.keyCode == 125 || event.keyCode == 124 {
            action = .selectNextScore
          } else if isUnmodified && (isEnter || isSpace) {
            action = .startGame
          } else if isUnmodified && isDelete, isImportedSelected() {
            action = .deleteSelectedScore
          } else {
            action = nil
          }
        case .game:
          if isUnmodified && isSpace {
            action = .advanceStep
          } else if isUnmodified && (isDelete || event.keyCode == 53) {
            action = .returnToMenu
          } else {
            action = nil
          }
        }

        if let action {
          Task { @MainActor in
            onAction(action)
          }
          return nil
        }
        return event
      }
    }
  }

  enum KeyboardAction {
    case startGame
    case returnToMenu
    case advanceStep
    case selectNextScore
    case selectPreviousScore
    case deleteSelectedScore
    case exitApp
  }
#endif
