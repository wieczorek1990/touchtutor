import SwiftUI

@MainActor
final class CircleAnimationHelper {
  static let defaultColor = Color(red: 12 / 255, green: 36 / 255, blue: 95 / 255)
  static let startColor = Color(red: 125 / 255, green: 211 / 255, blue: 252 / 255)

  private var task: Task<Void, Never>?

  func trigger(
    scaleSetter: @escaping (CGFloat) -> Void,
    colorSetter: @escaping (Color) -> Void,
    duration: Double
  ) {
    task?.cancel()
    withAnimation(.none) {
      scaleSetter(0.2)
      colorSetter(CircleAnimationHelper.startColor)
    }

    task = Task { @MainActor in
      try? await Task.sleep(nanoseconds: 16_000_000)
      guard !Task.isCancelled else { return }
      withAnimation(.linear(duration: duration)) {
        scaleSetter(1.0)
        colorSetter(CircleAnimationHelper.defaultColor)
      }
    }
  }

  func reset(scaleSetter: @escaping (CGFloat) -> Void, colorSetter: @escaping (Color) -> Void) {
    task?.cancel()
    scaleSetter(1.0)
    colorSetter(CircleAnimationHelper.defaultColor)
  }

  deinit {
    task?.cancel()
  }
}
