import SwiftUI

#if os(macOS)
  import AppKit
#endif

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
      HStack(spacing: 8) {
        Image(systemName: "music.note")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.blue)

        Text(
          viewModel.selectedScoreItem?.name
            ?? viewModel.score?.title
            ?? L10n.string("Touch Piano")
        )
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundColor(.primary)
        .lineLimit(1)
        .truncationMode(.tail)

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

          HStack(spacing: 8) {
            ProgressView(value: Double(current), total: Double(max(1, total)))
              .tint(.blue)
              .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
              viewModel.restart()
            }) {
              HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                  .font(.system(size: 10, weight: .bold))
                Text("Reset", bundle: .module)
                  .font(.system(size: 12, weight: .medium, design: .rounded))
              }
              .foregroundColor(.secondary)
              .padding(.horizontal, 7)
              .padding(.vertical, 3)
              .background(PlatformColors.controlBackground.opacity(0.7))
              .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(current == 0)
            .help(L10n.string("Reset score to start"))
          }
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
