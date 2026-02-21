import SwiftUI

struct TranscriptionResultView: View {
    @EnvironmentObject var appState: AppState
    @State private var copied = false

    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $appState.transcribedText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .frame(minHeight: 80, maxHeight: 150)

            GlassEffectContainer {
                VStack(spacing: 8) {
                    // Correction row
                    if appState.isCorrecting {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Correcting...")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect()
                    } else {
                        HStack(spacing: 8) {
                            Button {
                                appState.correctText(mode: .casual)
                            } label: {
                                Label("Casual", systemImage: "bubble.left")
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect()

                            Button {
                                appState.correctText(mode: .formal)
                            } label: {
                                Label("Formal", systemImage: "pencil.line")
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect()

                            Spacer()
                        }
                    }

                    // Action row
                    HStack(spacing: 8) {
                        Button {
                            appState.copyToClipboard()
                            withAnimation {
                                copied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    copied = false
                                }
                            }
                        } label: {
                            Label(copied ? "Copied!" : "Copy",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect()

                        Button {
                            appState.copyAndDismiss()
                        } label: {
                            Label("Copy & Close", systemImage: "doc.on.doc.fill")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.tint(.accentColor))

                        Spacer()

                        Button {
                            appState.dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.plain)
                        .frame(width: 28, height: 28)
                        .glassEffect(.regular, in: .circle)
                    }
                }
            }
            .controlSize(.small)
        }
    }
}
