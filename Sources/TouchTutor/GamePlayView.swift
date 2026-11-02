import SwiftUI

#if os(macOS)
  import AppKit
#endif

// Custom progress bar that shows measure segments and allows scrolling/dragging
struct MeasureProgressBar: View {
  let steps: [ScoreStep]
  let currentStepIndex: Int
  let onStepChanged: (Int) -> Void
  let onReset: () -> Void

  private var measureGroups: [(measure: Int, startIndex: Int, count: Int)] {
    var groups: [(measure: Int, startIndex: Int, count: Int)] = []
    guard !steps.isEmpty else { return groups }

    var currentMeasure = steps[0].measureNumber
    var startIdx = 0

    for (idx, step) in steps.enumerated() {
      if step.measureNumber != currentMeasure {
        groups.append((measure: currentMeasure, startIndex: startIdx, count: idx - startIdx))
        currentMeasure = step.measureNumber
        startIdx = idx
      }
    }
    groups.append((measure: currentMeasure, startIndex: startIdx, count: steps.count - startIdx))
    return groups
  }

  var body: some View {
    let groups = measureGroups
    if groups.isEmpty {
      Rectangle()
        .fill(Color.gray.opacity(0.2))
        .frame(height: 8)
        .cornerRadius(4)
    } else {
      HStack(spacing: 0) {
        Button(action: onReset) {
          Image(systemName: "arrow.counterclockwise")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.secondary)
            .frame(width: 20, height: 20)
            .background(PlatformColors.controlBackground.opacity(0.7))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(currentStepIndex == 0)
        .help(L10n.string("Reset score to start"))

        ScrollViewReader { proxy in
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
              ForEach(Array(groups.enumerated()), id: \.element.measure) { _, group in
                let measureWidth = CGFloat(group.count) * 12.0
                let completedInMeasure = max(
                  0, min(currentStepIndex, group.startIndex + group.count) - group.startIndex
                )
                let progress = CGFloat(completedInMeasure) / CGFloat(max(1, group.count))

                ZStack(alignment: .leading) {
                  // Background (gray track)
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: measureWidth, height: 8)

                  // Filled portion (blue)
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(width: max(0, measureWidth * progress - 1), height: 8)
                    .clipped()
                }
                .frame(width: measureWidth, height: 8)
                .contentShape(Rectangle())
                .onTapGesture {
                  let targetStep = group.startIndex + group.count / 2
                  onStepChanged(targetStep)
                }
                .id(group.measure)
              }
            }
            .padding(.leading, 2)
          }
          .frame(height: 20)
          .onChange(of: currentStepIndex) {
            // Find which measure group contains the current step
            for group in groups {
              if currentStepIndex >= group.startIndex
                && currentStepIndex < group.startIndex + group.count
              {
                withAnimation(.easeInOut(duration: 0.2)) {
                  proxy.scrollTo(group.measure, anchor: .center)
                }
                break
              }
            }
          }
        }

        Spacer(minLength: 0)
      }
      .frame(height: 20)
    }
  }
}

struct GamePlayView: View {
  @ObservedObject var viewModel: ScorePlayerViewModel

  private var timerBorderColor: Color {
    let progress = min(max((viewModel.circleScale - 0.2) / 0.8, 0), 1)
    return Color(
      red: 1 - 0.75 * progress,
      green: 0.6 * (1 - progress),
      blue: 0.6 * (1 - progress)
    ).opacity(0.9)
  }

  var body: some View {
    VStack(spacing: 12) {
      VStack(spacing: 2) {
        HStack(spacing: 8) {
          Image(systemName: "music.note")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.blue)

          Text(
            viewModel.selectedScoreItem?.title
              ?? viewModel.score?.title
              ?? L10n.string("Touch Piano")
          )
          .font(.system(size: 15, weight: .bold, design: .rounded))
          .foregroundColor(.primary)
          .lineLimit(1)
          .truncationMode(.tail)

        }

        Text(
          viewModel.selectedScoreItem?.artist
            ?? viewModel.score?.artist
            ?? ""
        )
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundColor(.secondary)
        .lineLimit(1)
        .truncationMode(.tail)
        .opacity(
          (viewModel.selectedScoreItem?.artist ?? viewModel.score?.artist ?? "").isEmpty
            ? 0 : 1
        )

        Text(
          viewModel.selectedScoreItem?.album
            ?? viewModel.score?.album
            ?? ""
        )
        .font(.system(size: 11, weight: .regular, design: .rounded))
        .foregroundColor(.secondary)
        .lineLimit(1)
        .truncationMode(.tail)
        .opacity(
          (viewModel.selectedScoreItem?.album ?? viewModel.score?.album ?? "").isEmpty
            ? 0 : 1
        )
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity, alignment: .center)
      .background(
        RoundedRectangle(cornerRadius: 9)
          .fill(PlatformColors.controlBackground.opacity(0.6))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 9)
          .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
      )

      HStack(spacing: 4) {
        Spacer(minLength: 0)

        Text("Tempo", bundle: .module)
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(.secondary)

        TempoSelectorView(selectedTempo: $viewModel.tempoAdjustment)
          .frame(width: 140)

        Spacer(minLength: 0)
      }

      if let score = viewModel.score {
        let total = score.steps.count
        let current = viewModel.currentStepIndex
        let percent = total > 0 ? Int((Double(current) / Double(total)) * 100) : 0

        VStack(spacing: 5) {
          HStack {
            Spacer()

            HStack(spacing: 12) {
              Label(
                L10n.format("Measure %lld", viewModel.currentStep?.measureNumber ?? 1),
                systemImage: "music.note")
              Label(L10n.format("Step %lld/%lld", current, total), systemImage: "metronome")
              Label(L10n.format("%lld%%", percent), systemImage: "chart.bar.fill")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer()
          }

          MeasureProgressBar(
            steps: score.steps,
            currentStepIndex: current,
            onStepChanged: { viewModel.jumpToStep($0) },
            onReset: { viewModel.restart() }
          )
        }
      }

      HStack(spacing: 8) {
        if let step = viewModel.currentStep ?? viewModel.score?.steps.first {
          ForEach(step.notes, id: \.self) { pitch in
            NoteCapsuleButton(pitch: pitch) {
              viewModel.playPitch(pitch)
            }
          }
        } else {
          Text("Ready", bundle: .module)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 5)
      .frame(maxWidth: 340, minHeight: 36)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(PlatformColors.textBackground.opacity(0.45))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
      )

      Spacer(minLength: 0)

      ZStack {
        RoundedRectangle(cornerRadius: 14)
          .stroke(
            timerBorderColor,
            style: StrokeStyle(lineWidth: 8, dash: [4, 4])
          )
          .frame(width: 260, height: 260)

        Button(action: {
          viewModel.advanceStep()
        }) {
          ZStack {
            ZStack(alignment: .topTrailing) {
              RoundedRectangle(cornerRadius: 14)
                .fill(
                  viewModel.isFinished
                    ? Color.purple
                    : (viewModel.isPressed
                      ? viewModel.circleColor.opacity(0.85) : viewModel.circleColor)
                )

              TriangleCorner(size: 54)
                .fill(Color(red: 251 / 255.0, green: 188 / 255.0, blue: 5 / 255.0))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .shadow(
              color: (viewModel.isFinished ? Color.purple : viewModel.circleColor.opacity(0.6)),
              radius: viewModel.isPressed ? 24 : 15,
              x: 0,
              y: 5
            )

            VStack(spacing: 8) {
              if viewModel.isFinished {
                Image(systemName: "pause.fill")
                  .font(.system(size: 42, weight: .bold))
                  .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
              } else if let step = viewModel.currentStep ?? viewModel.score?.steps.first {
                MusicalNoteSymbolView(
                  noteType: step.noteValueType,
                  isDotted: step.isDotted,
                  size: 38,
                  color: .white
                )
                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)

                if step.notes.count > 1 {
                  Text(step.notes.map(\.displayName).joined(separator: " "))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                } else if let single = step.notes.first {
                  Text(single.displayName)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 4)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                }

                if viewModel.currentStep == nil {
                  Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 2)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                }
              } else {
                Image(systemName: "play.fill")
                  .font(.system(size: 42, weight: .bold))
                  .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
              }
            }
            .foregroundColor(.white)
          }
          .frame(width: 260, height: 260)
          .scaleEffect((viewModel.isPressed ? 0.92 : 1.0) * viewModel.circleScale)
          .animation(.spring(response: 0.22, dampingFraction: 0.55), value: viewModel.isPressed)
          .frame(width: 260, height: 260)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
      .frame(width: 260, height: 260)

      Spacer(minLength: 0)
    }
  }
}
