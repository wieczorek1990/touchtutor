import Combine
import SwiftUI

#if os(macOS)
  import AppKit
#endif

enum AppScreen {
  case menu
  case game
}

@MainActor
final class ScorePlayerViewModel: ObservableObject {
  @Published var currentScreen: AppScreen = .menu
  @Published var availableScores: [ScoreItem] = ScoreItem.defaultScores
  @Published var selectedScoreItem: ScoreItem?
  @Published var score: ParsedScore?
  @Published var currentStepIndex: Int = 0
  @Published var currentStep: ScoreStep?
  @Published var isPressed: Bool = false
  @Published var isFinished: Bool = false
  @Published var circleScale: CGFloat = 1.0
  @Published var circleColor: Color = CircleAnimationHelper.defaultColor
  @Published var tempoAdjustment: TempoAdjustment = .normal
  @Published var selectedSoundFont: SoundFont = .piano

  @Published var libraryError: String?
  @Published var isShowingScoreStore = false
  @Published private(set) var storeState = ScorePackStoreState()
  let scoreStore: ScorePackStore

  private let importedLibrary: ImportedScoreLibrary
  private var soundFontSynth: SoundFontSynth
  private let circleAnimation = CircleAnimationHelper()
  private var cancellables = Set<AnyCancellable>()
  #if os(macOS)
    private var keyboardMonitor: KeyboardMonitor?
  #endif

  init(
    importedLibrary: ImportedScoreLibrary = ImportedScoreLibrary(),
    soundFontSynth: SoundFontSynth = SoundFontSynth(),
    scoreStore: ScorePackStore = ScorePackStore()
  ) {
    self.importedLibrary = importedLibrary
    self.soundFontSynth = soundFontSynth
    self.scoreStore = scoreStore
    self.storeState = scoreStore.state
    #if DEBUG
      // Debug order: Test → C Major → Free → Paid
      let freeDefaults = availableScores
      availableScores = []
      // 1. Test scores (free)
      let testIds = ["test", "test_long_title"]
      for id in testIds {
        if let testScore = freeDefaults.first(where: { $0.id == id }) {
          availableScores.append(testScore)
        }
      }
      // 2. C Major Pack scores
      for pack in scoreStore.packs {
        if pack.id == "tech.soiree.touchtutor.scorepacks.cmajor" {
          availableScores.append(contentsOf: pack.scores)
        }
      }
      // 3. Free defaults (excluding Test)
      availableScores.append(contentsOf: freeDefaults.filter { !testIds.contains($0.id) })
      // 4. Paid (Final Fantasy scores)
      for pack in scoreStore.packs {
        if pack.id == "tech.soiree.touchtutor.scorepacks.finalfantasy.1" {
          availableScores.append(contentsOf: pack.scores)
        }
      }
      // 5. Paid (Final Fantasy (2) scores)
      for pack in scoreStore.packs {
        if pack.id == "tech.soiree.touchtutor.scorepacks.finalfantasy.2" {
          availableScores.append(contentsOf: pack.scores)
        }
      }
      // 5. Paid (BMV scores)
      for pack in scoreStore.packs {
        if pack.id == "tech.soiree.touchtutor.scorepacks.bmv" {
          availableScores.append(contentsOf: pack.scores)
        }
      }
    #else
      // Release order: Free defaults → Paid
      for pack in scoreStore.packs {
        availableScores.append(contentsOf: pack.scores)
      }
    #endif
    scoreStore.onChange = { [weak self] state in
      guard let self else { return }
      self.storeState = state
      if let selected = self.selectedScoreItem, !state.canPlay(selected) {
        self.score = nil
        self.restart()
        self.returnToMenu()
      } else if let selected = self.selectedScoreItem, self.score == nil {
        self.selectScore(selected)
      }
    }
    do {
      availableScores.append(contentsOf: try importedLibrary.loadScores())
    } catch {
      libraryError = error.localizedDescription
    }
    if let initialScore = availableScores.first(where: { storeState.canPlay($0) })
      ?? availableScores.first
    {
      selectScore(initialScore)
    }

    $selectedSoundFont
      .sink { [soundFontSynth] soundFont in
        soundFontSynth.setProgram(soundFont.program)
      }
      .store(in: &cancellables)
    #if os(macOS)
      keyboardMonitor = KeyboardMonitor(
        currentScreen: { [weak self] in self?.currentScreen ?? .menu },
        isShowingStore: { [weak self] in self?.isShowingScoreStore ?? false },
        isImportedSelected: { [weak self] in self?.selectedScoreItem?.isImported ?? false },
        onAction: { [weak self] action in
          switch action {
          case .startGame:
            self?.startGame()
          case .returnToMenu:
            self?.returnToMenu()
          case .advanceStep:
            self?.advanceStep()
          case .selectNextScore:
            self?.selectNextScore()
          case .selectPreviousScore:
            self?.selectPreviousScore()
          case .deleteSelectedScore:
            if let selected = self?.selectedScoreItem {
              self?.deleteScore(selected)
            }
          case .exitApp:
            self?.exitApp()
          }
        }
      )
    #endif
  }

  func startGame() {
    guard let selected = selectedScoreItem else { return }
    guard storeState.canPlay(selected) else {
      isShowingScoreStore = true
      return
    }
    if score == nil {
      // Try to load the score if it hasn't been parsed yet
      if let parsed = MusicXMLParser.loadScore(item: selected) {
        score = parsed
      } else {
        return
      }
    }
    circleScale = 0.2
    withAnimation(.easeInOut(duration: 0.22)) {
      currentScreen = .game
    }
  }

  func returnToMenu() {
    withAnimation(.easeInOut(duration: 0.22)) {
      currentScreen = .menu
    }
  }

  #if os(macOS)
    func exitApp() {
      NSApplication.shared.terminate(nil)
    }

  #endif

  func selectScore(_ item: ScoreItem) {
    guard storeState.canPlay(item) else {
      selectedScoreItem = item
      score = nil
      restart()
      returnToMenu()
      isShowingScoreStore = true
      return
    }
    guard let parsed = MusicXMLParser.loadScore(item: item) else { return }
    selectScore(item, parsed: parsed)
  }

  private func selectScore(_ item: ScoreItem, parsed: ParsedScore) {
    selectedScoreItem = item
    score = parsed
    restart()
  }

  func selectNextScore() {
    moveSelection(by: 1)
  }

  func selectPreviousScore() {
    moveSelection(by: -1)
  }

  private func moveSelection(by offset: Int) {
    guard !availableScores.isEmpty else { return }
    guard let currentIndex = availableScores.firstIndex(where: { $0.id == selectedScoreItem?.id })
    else {
      selectScore(availableScores[0])
      return
    }
    let nextIndex = min(max(currentIndex + offset, 0), availableScores.count - 1)
    if nextIndex != currentIndex {
      selectedScoreItem = availableScores[nextIndex]
    }
  }

  func deleteScore(_ item: ScoreItem) {
    guard item.isImported else { return }
    guard let index = availableScores.firstIndex(where: { $0.id == item.id }) else { return }

    do {
      try importedLibrary.deleteScore(item)
    } catch {
      libraryError = error.localizedDescription
      return
    }

    let wasSelected = (selectedScoreItem?.id == item.id)
    availableScores.remove(at: index)

    if wasSelected {
      if availableScores.indices.contains(index) {
        selectScore(availableScores[index])
      } else if let last = availableScores.last {
        selectScore(last)
      } else {
        selectedScoreItem = nil
        score = nil
        restart()
      }
    }
  }

  #if os(macOS)
    func openCustomScoreFile() {
      let panel = NSOpenPanel()
      panel.title = L10n.string("Select MusicXML Score")
      panel.allowedContentTypes = [.xml]
      panel.allowsOtherFileTypes = true
      panel.canChooseFiles = true
      panel.canChooseDirectories = false
      panel.allowsMultipleSelection = false

      if panel.runModal() == .OK, let url = panel.url {
        do {
          try importScore(from: url)
        } catch {
          libraryError = error.localizedDescription
        }
      }
    }

  #endif

  func importScore(from url: URL) throws {
    let imported = try importedLibrary.importScore(from: url)
    if !availableScores.contains(where: { $0.id == imported.item.id }) {
      availableScores.append(imported.item)
    }
    selectScore(imported.item, parsed: imported.score)
  }

  func advanceStep() {
    guard let selected = selectedScoreItem, storeState.canPlay(selected) else {
      returnToMenu()
      return
    }
    guard let score = score, !score.steps.isEmpty else {
      soundFontSynth.playSingle(midiNote: 60)
      circleAnimation.trigger(
        scaleSetter: { self.circleScale = $0 },
        colorSetter: { self.circleColor = $0 },
        duration: 0.8 * tempoAdjustment.durationMultiplier
      )
      triggerButtonPulse()
      return
    }

    if isFinished {
      restart()
      return
    }

    if currentStepIndex < score.steps.count {
      let step = score.steps[currentStepIndex]
      currentStep = step
      soundFontSynth.play(midiNotes: step.notes.map(\.midiNote))
      currentStepIndex += 1

      if currentStepIndex >= score.steps.count {
        isFinished = true
      }

      let stepDuration = step.durationSeconds * tempoAdjustment.durationMultiplier
      circleAnimation.trigger(
        scaleSetter: { self.circleScale = $0 },
        colorSetter: { self.circleColor = $0 },
        duration: stepDuration
      )
    } else {
      isFinished = true
    }

    triggerButtonPulse()
  }

  func playPitch(_ pitch: ScorePitch) {
    guard let selected = selectedScoreItem, storeState.canPlay(selected) else { return }
    soundFontSynth.playSingle(midiNote: pitch.midiNote)
  }

  func restart() {
    circleAnimation.reset(
      scaleSetter: { self.circleScale = $0 },
      colorSetter: { self.circleColor = $0 }
    )
    currentStepIndex = 0
    currentStep = nil
    isFinished = false
  }

  func jumpToStep(_ index: Int) {
    guard let score = score, !score.steps.isEmpty else { return }
    let clampedIndex = min(max(index, 0), score.steps.count)
    circleAnimation.reset(
      scaleSetter: { self.circleScale = $0 },
      colorSetter: { self.circleColor = $0 }
    )
    currentStepIndex = clampedIndex
    if clampedIndex < score.steps.count {
      currentStep = score.steps[clampedIndex]
      isFinished = false
    } else {
      currentStep = nil
      isFinished = false
    }
  }

  private func triggerButtonPulse() {
    isPressed = true
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 180_000_000)
      self.isPressed = false
    }
  }
}
