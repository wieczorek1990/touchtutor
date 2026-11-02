import AVFoundation
import AudioToolbox
@preconcurrency import ObjectiveC

@MainActor
final class SoundFontSynth {
  private let engine = AVAudioEngine()
  private let sampler = AVAudioUnitSampler()
  private var instrumentGeneration = 0
  private var currentProgram: UInt8 = 0
  private var loadedPrograms: Set<UInt8> = []
  private var isReady = false

  init() {
    engine.attach(sampler)
    if #available(iOS 27.0, *) {
      try? engine.connectNode(sampler, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: nil)
    } else {
      engine.connect(sampler, to: engine.mainMixerNode, format: nil)
    }
    Task.detached { [weak self] in
      try? self?.engine.start()
      await MainActor.run {
        self?.isReady = true
      }
    }
  }

  /// Switch to a different instrument program.
  func setProgram(_ program: UInt8) {
    guard isReady else { return }
    guard program != currentProgram else { return }
    currentProgram = program
    ensureInstrumentLoaded(program)
    sampler.sendProgramChange(program, onChannel: 0)
  }

  private static func resolveBankURL() -> URL? {
    let systemBankPath =
      "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
    let systemBankURL = URL(fileURLWithPath: systemBankPath)
    if FileManager.default.fileExists(atPath: systemBankURL.path) {
      return systemBankURL
    }
    return nil
  }

  private func loadProgram(_ program: UInt8) {
    let neededPrograms: [UInt8] = [0, 25, 27]  // Piano, Jazz Guitar, Electric Guitar
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
    sampler.sendProgramChange(program, onChannel: 0)
  }

  private func ensureInstrumentLoaded(_ program: UInt8) {
    guard !loadedPrograms.contains(program) else { return }
    loadProgram(program)
  }

  func play(midiNotes: [UInt8], sustainDurationNanoseconds: UInt64 = 3_000_000_000) {
    guard isReady else { return }
    ensureInstrumentLoaded(currentProgram)
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
