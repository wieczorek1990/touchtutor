import AVFoundation
import AudioToolbox
@preconcurrency import ObjectiveC

@MainActor
final class SoundFontSynth {
  private let engine = AVAudioEngine()
  private let sampler = AVAudioUnitSampler()
  private let reverb = AVAudioUnitReverb()
  private var loadedPrograms: Set<UInt8> = []
  private var instrumentGeneration = 0
  private var currentProgram: UInt8 = 0

  @Published private(set) var isLoading = false

  init() {
    engine.attach(sampler)
    engine.attach(reverb)

    reverb.loadFactoryPreset(.mediumHall)
    reverb.wetDryMix = 22

    if #available(macOS 27.0, *) {
      try? engine.connectNode(sampler, to: reverb, fromBus: 0, toBus: 0, format: nil)
      try? engine.connectNode(reverb, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: nil)
    } else {
      engine.connect(sampler, to: reverb, format: nil)
      engine.connect(reverb, to: engine.mainMixerNode, format: nil)
    }
    try? engine.start()
  }

  /// Switch to a different instrument program.
  func setProgram(_ program: UInt8) {
    guard program != currentProgram else { return }
    currentProgram = program
    if loadedPrograms.contains(program) {
      // Instrument already loaded; just switch via program change (fast path).
      sampler.sendProgramChange(program, onChannel: 0)
    } else {
      // Load this instrument on-demand.
      Task { @MainActor in
        await self.loadProgram(program)
      }
    }
  }

  private static func resolveBankURL() -> URL? {
    // Use system DLS for fast loading (bundled SF3 files are too large and freeze the UI).
    let systemBankPath =
      "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
    let systemBankURL = URL(fileURLWithPath: systemBankPath)
    if FileManager.default.fileExists(atPath: systemBankURL.path) {
      return systemBankURL
    }
    return nil
  }

  /// Loads all needed instrument programs from the sound bank.
  private func loadProgram(_ program: UInt8) async {
    let neededPrograms: [UInt8] = [0, 25, 27]  // Piano, Jazz Guitar, Electric Guitar
    guard !loadedPrograms.contains(program) else { return }
    guard let bankURL = Self.resolveBankURL() else { return }

    for p in neededPrograms where !loadedPrograms.contains(p) {
      do {
        try self.sampler.loadSoundBankInstrument(
          at: bankURL,
          program: p,
          bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
          bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
        self.loadedPrograms.insert(p)
      } catch {
        print("Unable to load instrument (program \(p)): \(error.localizedDescription)")
      }
    }
    self.sampler.sendProgramChange(program, onChannel: 0)
  }

  /// Synchronous fallback for play() — ensures all needed programs are loaded.
  private func ensureInstrumentLoaded() {
    let neededPrograms: [UInt8] = [0, 25, 27]  // Piano, Jazz Guitar, Electric Guitar
    guard !loadedPrograms.contains(currentProgram) else { return }
    guard let bankURL = Self.resolveBankURL() else { return }

    for program in neededPrograms where !loadedPrograms.contains(program) {
      do {
        try sampler.loadSoundBankInstrument(
          at: bankURL,
          program: program,
          bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
          bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
        loadedPrograms.insert(program)
      } catch {
        print("Unable to load instrument (program \(program)): \(error.localizedDescription)")
      }
    }
    sampler.sendProgramChange(currentProgram, onChannel: 0)
  }

  func play(midiNotes: [UInt8], sustainDurationNanoseconds: UInt64 = 3_000_000_000) {
    ensureInstrumentLoaded()
    sampler.sendController(123, withValue: 0, onChannel: 0)
    let generation = instrumentGeneration
    for note in midiNotes {
      sampler.startNote(note, withVelocity: 88, onChannel: 0)
    }

    Task { @MainActor in
      try? await Task.sleep(nanoseconds: sustainDurationNanoseconds)
      guard generation == self.instrumentGeneration else { return }
      for note in midiNotes {
        self.sampler.stopNote(note, onChannel: 0)
      }
    }
  }

  func playSingle(midiNote: UInt8 = 60) {
    play(midiNotes: [midiNote])
  }
}
