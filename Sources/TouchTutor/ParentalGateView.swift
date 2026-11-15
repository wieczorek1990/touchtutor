import Foundation
import SwiftUI

/// A parental gate that requires the user to draw a pattern on a 3×3 grid
/// before performing a protected action (leaving the app or making a purchase).
/// This gate is intentionally hardcoded and cannot be disabled — there is no
/// setting, toggle, or environment variable that bypasses it.

private let hasLaunchedBeforeKey = "touchtutor_hasLaunchedBefore"

/// Represents a cell in the 3×3 pattern grid (row, column) 0-based.
struct GridCell: Hashable, Identifiable {
  let row: Int
  let col: Int
  var id: String { "\(row)-\(col)" }
}

@MainActor
final class ParentalGateManager: ObservableObject {
  /// Singleton shared instance — the gate is always active and cannot be turned off.
  static let shared = ParentalGateManager()

  /// When true, the gate overlay is presented and blocks interaction.
  @Published var isPresented = false

  /// When true, the splash logos have finished and the gate may appear immediately.
  @Published var splashComplete = false

  /// The set of cells the user has toggled on.
  @Published var selectedCells: Set<GridCell> = []

  /// Feedback state: nil = no attempt yet, true = correct, false = wrong.
  @Published var feedbackState: Bool?

  /// The closure to execute once the gate is passed.
  var onPass: (() -> Void)?

  /// Pending action while waiting for splash to finish.
  var pendingOnPass: (() -> Void)?

  /// Returns true if this is the very first launch of the app.
  var isFirstLaunch: Bool {
    !UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey)
  }

  /// Mark the first launch as complete so the gate won't auto-trigger again.
  func markFirstLaunchComplete() {
    UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
  }

  /// The correct pattern: the 4 cells that form an L shape.
  private let correctPattern: Set<GridCell> = [
    GridCell(row: 0, col: 1),  // top-center
    GridCell(row: 1, col: 1),  // middle-center
    GridCell(row: 2, col: 1),  // bottom-center
    GridCell(row: 2, col: 2),  // bottom-right
  ]

  /// Present the gate with a fresh state. Waits for splash logos to finish first.
  func present(onPass: (() -> Void)?) {
    self.pendingOnPass = onPass
    selectedCells = []
    feedbackState = nil
    if splashComplete {
      isPresented = true
      self.onPass = onPass
    } else {
      // Wait until splash is done, then show the gate.
      Task { @MainActor in
        while !splashComplete {
          try? await Task.sleep(nanoseconds: 100_000_000)
        }
        isPresented = true
        self.onPass = onPass
      }
    }
  }

  /// Mark splash logos as complete so any pending gate can appear.
  func markSplashComplete() {
    splashComplete = true
  }

  /// Called when the user taps a cell to toggle it on/off.
  func toggleCell(_ cell: GridCell) {
    // Ignore input after a wrong attempt until reset.
    if feedbackState == false { return }

    if selectedCells.contains(cell) {
      selectedCells.remove(cell)
    } else {
      // If the cell is not part of the correct pattern, fail immediately.
      if !correctPattern.contains(cell) {
        feedbackState = false
        selectedCells = []
        Task { @MainActor in
          try? await Task.sleep(nanoseconds: 1_000_000_000)
          feedbackState = nil
        }
        return
      }
      selectedCells.insert(cell)
    }

    // Check if the pattern is complete.
    if selectedCells == correctPattern {
      feedbackState = true
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 500_000_000)
        isPresented = false
        selectedCells = []
        feedbackState = nil
        onPass?()
      }
    }
  }
}

/// The full-screen parental gate overlay view with a 3×3 pattern grid.
struct ParentalGateView: View {
  @ObservedObject private var manager = ParentalGateManager.shared

  private let gridSize = 3
  private let cellSize: CGFloat = 60
  private let spacing: CGFloat = 16

  private var gridDimension: CGFloat {
    CGFloat(gridSize - 1) * (cellSize + spacing) + cellSize
  }

  var body: some View {
    ZStack {
      PlatformColors.windowBackground
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 24) {
        Spacer()

        Image(systemName: "lock.shield.fill")
          .font(.system(size: 56))
          .foregroundColor(.blue)

        Text("Please draw L. in the middle from circles.", bundle: .module)
          .font(.title.bold())

        // 3x3 grid with toggle circles
        VStack(spacing: spacing) {
          ForEach(0..<gridSize, id: \.self) { row in
            HStack(spacing: spacing) {
              ForEach(0..<gridSize, id: \.self) { col in
                let cell = GridCell(row: row, col: col)
                let isSelected = manager.selectedCells.contains(cell)
                ZStack {
                  // Outer pulse ring for selected cells
                  if isSelected {
                    Circle()
                      .stroke(Color.blue.opacity(0.4), lineWidth: 4)
                      .frame(width: cellSize + 16, height: cellSize + 16)
                      .transition(.scale(scale: 0.5).combined(with: .opacity))
                  }
                  // Main circle
                  Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: cellSize, height: cellSize)
                    .overlay {
                      Circle()
                        .stroke(
                          isSelected ? Color.blue : Color.gray.opacity(0.5),
                          lineWidth: 2
                        )
                    }
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
                .onTapGesture {
                  manager.toggleCell(cell)
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)
              }
            }
          }
        }

        // Feedback
        if manager.feedbackState == false {
          Text("Incorrect pattern. Try again.", bundle: .module)
            .font(.callout.bold())
            .foregroundColor(.red)
            .transition(.opacity)
        }

        Spacer()
      }
      .padding(.horizontal, 32)
    }
    .ignoresSafeArea()
  }
}
