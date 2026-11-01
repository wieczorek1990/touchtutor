import SwiftUI

struct TempoSelectorView: View {
  @Binding var selectedTempo: TempoAdjustment

  var body: some View {
    HStack(spacing: 4) {
      ForEach(TempoAdjustment.allCases) { tempo in
        let isSelected = selectedTempo == tempo
        Button(action: {
          withAnimation(.easeInOut(duration: 0.15)) {
            selectedTempo = tempo
          }
        }) {
          Text(tempo.displayName)
            .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
            .foregroundColor(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
              RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue : PlatformColors.controlBackground.opacity(0.5))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 10)
                .stroke(
                  isSelected ? Color.blue.opacity(0.8) : Color.secondary.opacity(0.15), lineWidth: 1
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
  }
}
