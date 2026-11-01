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
    sampler.sendProgramChange(program, onChannel: 0)
  }

  private static func resolveSoundFontURL() -> URL? {
    Bundle.main.url(forResource: "MS Basic", withExtension: "sf2")
  }

  /// Loads the MS Basic soundfont.
  private func loadSoundFont() async {
    guard let sfURL = Self.resolveSoundFontURL() else { return }
    do {
      try sampler.loadSoundBankInstrument(
        at: sfURL,
        program: 0,
        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
        bankLSB: UInt8(kAUSampler_DefaultBankLSB)
      )
      self.loaded = true
    } catch {
      print("Unable to load MS Basic.sf2: \(error.localizedDescription)")
    }
  }

  private var loaded = false

  /// Synchronous fallback for play() — ensures the soundfont is loaded.
  private func ensureSoundFontLoaded() {
    guard !loaded else { return }
    guard let sfURL = Self.resolveSoundFontURL() else { return }
    do {
      try sampler.loadSoundBankInstrument(
        at: sfURL,
        program: 0,
        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
        bankLSB: UInt8(kAUSampler_DefaultBankLSB)
      )
      loaded = true
    } catch {
      print("Unable to load MS Basic.sf2: \(error.localizedDescription)")
    }
  }

  func play(midiNotes: [UInt8], sustainDurationNanoseconds: UInt64 = 3_000_000_000) {
    ensureSoundFontLoaded()
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
