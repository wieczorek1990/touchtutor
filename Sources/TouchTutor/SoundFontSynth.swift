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
      await self.loadPianoInstrument()
    }
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

  /// Loads the piano instrument on a background thread.
  private func loadPianoInstrument() async {
    guard let bankURL = Self.resolveBankURL() else { return }

    do {
      try await Task.sleep(nanoseconds: 10_000_000)
      try await MainActor.run {
        try self.sampler.loadSoundBankInstrument(
          at: bankURL,
          program: 0,
          bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
          bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
        self.sampler.sendProgramChange(0, onChannel: 0)
        self.instrumentLoaded = true
      }
    } catch {
      print("Unable to load piano instrument: \(error.localizedDescription)")
    }
  }

  /// Synchronous fallback for play() — ensures piano is loaded before playing.
  private func ensureInstrumentLoaded() {
    guard !instrumentLoaded else { return }
    guard let bankURL = Self.resolveBankURL() else { return }

    instrumentGeneration += 1
    engine.reset()
    sampler.sendController(120, withValue: 0, onChannel: 0)

    do {
      try sampler.loadSoundBankInstrument(
        at: bankURL,
        program: 0,
        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
        bankLSB: UInt8(kAUSampler_DefaultBankLSB)
      )
      sampler.sendProgramChange(0, onChannel: 0)
      instrumentLoaded = true
    } catch {
      print("Unable to load piano instrument: \(error.localizedDescription)")
    }
  }

  func play(midiNotes: [UInt8], sustainDurationNanoseconds: UInt64 = 3_000_000_000) {
    ensureInstrumentLoaded()
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
