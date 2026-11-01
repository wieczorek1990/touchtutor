import AVFoundation
import AudioToolbox
@preconcurrency import ObjectiveC

@MainActor
final class SoundFontSynth {
  private let engine = AVAudioEngine()
  private let sampler = AVAudioUnitSampler()
  private let reverb = AVAudioUnitReverb()
  private var instrumentLoaded = false
  private var instrumentGeneration = 0
  private var currentProgram: UInt8 = 0

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

    Task { @MainActor in
      await self.loadInstrument(program: 0)
    }
  }

  /// Switch to a different instrument program.
  func setProgram(_ program: UInt8) {
    guard program != currentProgram else { return }
    currentProgram = program
    Task { @MainActor in
      await self.loadInstrument(program: program)
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

  /// Loads a single instrument program.
  private func loadInstrument(program: UInt8) async {
    guard let bankURL = Self.resolveBankURL() else { return }

    // AVAudioUnitSampler is not thread-safe; loadSoundBankInstrument must run on the main thread.
    do {
      try self.sampler.loadSoundBankInstrument(
        at: bankURL,
        program: program,
        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
        bankLSB: UInt8(kAUSampler_DefaultBankLSB)
      )
      self.instrumentGeneration += 1
      self.engine.reset()
      self.sampler.sendController(120, withValue: 0, onChannel: 0)
      self.sampler.sendProgramChange(program, onChannel: 0)
      self.instrumentLoaded = true
    } catch {
      print("Unable to load instrument (program \(program)): \(error.localizedDescription)")
    }
  }

  /// Synchronous fallback for play() — ensures an instrument is loaded before playing.
  private func ensureInstrumentLoaded() {
    guard !instrumentLoaded else { return }
    guard let bankURL = Self.resolveBankURL() else { return }

    instrumentGeneration += 1
    engine.reset()
    sampler.sendController(120, withValue: 0, onChannel: 0)

    do {
      try sampler.loadSoundBankInstrument(
        at: bankURL,
        program: currentProgram,
        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
        bankLSB: UInt8(kAUSampler_DefaultBankLSB)
      )
      sampler.sendProgramChange(currentProgram, onChannel: 0)
      instrumentLoaded = true
    } catch {
      print("Unable to load instrument (program \(currentProgram)): \(error.localizedDescription)")
    }
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
