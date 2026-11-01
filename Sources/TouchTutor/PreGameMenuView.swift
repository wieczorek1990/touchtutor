import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
  import AppKit
#endif

struct PreGameMenuView: View {
  @ObservedObject var viewModel: ScorePlayerViewModel
  #if os(iOS)
    @State private var isImporting = false
    @State private var importError: String?
  #endif

  var body: some View {
    VStack(spacing: 16) {
      VStack(spacing: 6) {
        MusicNoteLogoView(size: 36)
        Text("TouchTutor", bundle: .module)
          .font(.system(size: 18, weight: .bold, design: .rounded))
          .foregroundColor(.primary)
      }
      .padding(.top, 4)
      .frame(maxWidth: .infinity)

      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text("Scores", bundle: .module)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
          Spacer()
          Button {
            viewModel.isShowingScoreStore = true
          } label: {
            Text("Packs", bundle: .module)
              .font(.caption.weight(.semibold))
          }
          .buttonStyle(.borderless)
          Button(action: {
            #if os(iOS)
              isImporting = true
            #else
              viewModel.openCustomScoreFile()
            #endif
          }) {
            HStack(spacing: 5) {
              Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
              Text("Import", bundle: .module)
                .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.12))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
          }
          .buttonStyle(.plain)
        }
        .padding(.horizontal, 2)

        ScrollViewReader { proxy in
          ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 5) {
              ForEach(viewModel.availableScores) { item in
                let isSelected = viewModel.selectedScoreItem?.id == item.id
                let packColor = viewModel.scoreStore.packs.first {
                  $0.id == item.requiredProductID
                }?.color
                let rowColor = packColor ?? Color.blue
                let backgroundColor: Color =
                  isSelected
                  ? rowColor.opacity(packColor == nil ? 0.12 : 0.24)
                  : (packColor?.opacity(0.12) ?? PlatformColors.controlBackground.opacity(0.6))
                let borderColor: Color =
                  isSelected
                  ? rowColor.opacity(packColor == nil ? 0.4 : 0.8)
                  : (packColor?.opacity(0.4) ?? Color.secondary.opacity(0.12))
                let borderWidth: CGFloat = isSelected && packColor != nil ? 2 : 1
                HStack(spacing: 8) {
                  Button(action: {
                    viewModel.selectScore(item)
                  }) {
                    VStack(alignment: .leading, spacing: 2) {
                      HStack(spacing: 8) {
                        Text(item.name)
                          .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                          .foregroundColor(.primary)
                          .lineLimit(1)
                          .truncationMode(.tail)

                        if item.requiredProductID != nil {
                          let isUnlocked = viewModel.storeState.canPlay(item)
                          Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                            .accessibilityLabel(
                              isUnlocked
                                ? Text("Unlocked score", bundle: .module)
                                : Text("Locked score", bundle: .module))
                        }

                        if item.isImported {
                          Text("imported", bundle: .module)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Spacer(minLength: 4)
                      }

                      Text(item.defaultArtist)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                      Text(item.defaultAlbum)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    }
                    .padding(.leading, 11)
                    .padding(.trailing, item.isImported ? 0 : 11)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                  }
                  .buttonStyle(.plain)
                  .simultaneousGesture(
                    TapGesture(count: 2).onEnded {
                      viewModel.selectScore(item)
                      viewModel.startGame()
                    })

                  if item.isImported {
                    Button(action: {
                      viewModel.deleteScore(item)
                    }) {
                      Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                        .padding(4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(L10n.string("Delete imported score"))
                  }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
                )
                .id(item.id)
                .contextMenu {
                  if item.isImported {
                    Button(role: .destructive) {
                      viewModel.deleteScore(item)
                    } label: {
                      Label(L10n.string("Delete Score"), systemImage: "trash")
                    }
                  }
                }
              }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
          }
          .frame(minHeight: 60, maxHeight: .infinity)
          .onChange(of: viewModel.selectedScoreItem?.id) {
            if let id = viewModel.selectedScoreItem?.id {
              withAnimation(.easeInOut(duration: 0.15)) {
                proxy.scrollTo(id, anchor: nil)
              }
            }
          }
        }
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(PlatformColors.textBackground.opacity(0.35))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
      )

      Spacer(minLength: 0)

      VStack(spacing: 10) {
        Button(action: {
          viewModel.startGame()
        }) {
          HStack(spacing: 8) {
            Image(systemName: "play.fill")
              .font(.system(size: 16, weight: .bold))
            Text("Play", bundle: .module)
              .font(.system(size: 17, weight: .bold, design: .rounded))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.blue)
              .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 3)
          )
        }
        .buttonStyle(.plain)

        #if os(macOS)
          Button(action: {
            viewModel.exitApp()
          }) {
            HStack(spacing: 6) {
              Image(systemName: "power")
                .font(.system(size: 13, weight: .semibold))
              Text("Exit", bundle: .module)
                .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
              RoundedRectangle(cornerRadius: 10)
                .fill(PlatformColors.controlBackground.opacity(0.4))
            )
          }
          .buttonStyle(.plain)
        #endif
      }
    }
    #if os(iOS)
      .fileImporter(isPresented: $isImporting, allowedContentTypes: [.xml, .data]) { result in
        do {
          try viewModel.importScore(from: result.get())
        } catch {
          importError = error.localizedDescription
        }
      }
      .alert(
        "Unable to Import Score",
        isPresented: Binding(
          get: { importError != nil },
          set: { if !$0 { importError = nil } }
        )
      ) {
        Button("OK", role: .cancel) { importError = nil }
      } message: {
        Text(importError ?? "")
      }
    #endif
  }
}
