import SwiftUI

#if os(macOS)
  import AppKit

  struct MacMenuCommands: Commands {
    @ObservedObject var viewModel: ScorePlayerViewModel

    var body: some Commands {
      CommandGroup(replacing: .appInfo) {
        Button {
          #if DEBUG
            let buildType = L10n.string("Debug build")
          #else
            let buildType = L10n.string("Release build")
          #endif
          NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(string: buildType)
          ])
        } label: {
          Text("About TouchTutor", bundle: .module)
        }
      }

      CommandMenu(L10n.string("Game")) {
        if viewModel.currentScreen == .menu {
          Button(L10n.string("Play Score")) {
            viewModel.startGame()
          }
        } else {
          Button(L10n.string("Return to Menu")) {
            viewModel.returnToMenu()
          }
          .keyboardShortcut(.delete, modifiers: [])
        }

        Divider()

        Button(L10n.string("Exit TouchTutor")) {
          viewModel.exitApp()
        }
        .keyboardShortcut("q", modifiers: [.command])
      }

      CommandMenu(L10n.string("Score")) {
        ForEach(viewModel.availableScores) { item in
          Button(action: {
            viewModel.selectScore(item)
          }) {
            let prefix = viewModel.selectedScoreItem?.id == item.id ? "✓ " : "   "
            let suffix = item.isImported ? L10n.string(" [Imported]") : ""
            Text("\(prefix)\(item.name)\(suffix)")
          }
        }

        Divider()

        Button(L10n.string("Open MusicXML Score...")) {
          viewModel.openCustomScoreFile()
        }
        .keyboardShortcut("o", modifiers: [.command])

        if let selected = viewModel.selectedScoreItem, selected.isImported {
          Button(L10n.string("Delete Imported Score")) {
            viewModel.deleteScore(selected)
          }
        }

        Divider()

        Button(L10n.string("Restart Current Score")) {
          viewModel.restart()
        }
        .keyboardShortcut("r", modifiers: [.command])
      }

      CommandMenu(L10n.string("Tempo")) {
        ForEach(TempoAdjustment.allCases) { tempo in
          Button(action: {
            viewModel.tempoAdjustment = tempo
          }) {
            let prefix = viewModel.tempoAdjustment == tempo ? "✓ " : "   "
            Text("\(prefix)\(tempo.displayName)")
          }
        }
      }

      CommandGroup(after: .windowArrangement) {
        Button(L10n.string("Center")) {
          centerMainWindow()
        }
        .keyboardShortcut("c", modifiers: [.control])
      }
    }
  }
#endif
