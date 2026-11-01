import SwiftUI

struct SoundFontSelectorView: View {
  @Binding var selectedSoundFont: SoundFont

  var body: some View {
    Menu {
      ForEach(SoundFont.allCases) { soundFont in
        Button(action: {
          withAnimation(.easeInOut(duration: 0.15)) {
            selectedSoundFont = soundFont
          }
        }) {
          HStack {
            Text(soundFont.displayName)
            if selectedSoundFont == soundFont {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    } label: {
      HStack {
        Text(selectedSoundFont.displayName)
          .font(.system(size: 11, weight: .medium, design: .rounded))
        Spacer()
        Image(systemName: "chevron.up.chevron.down")
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(.secondary)
      }
      .frame(height: 34)
      .padding(.horizontal, 10)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(PlatformColors.controlBackground.opacity(0.5))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
      )
    }
    .menuStyle(.borderlessButton)
    .menuIndicator(.hidden)
  }
}
