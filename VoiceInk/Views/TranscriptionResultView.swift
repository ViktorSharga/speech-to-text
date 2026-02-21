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
                .keyboardShortcut("c", modifiers: .command)

                Button {
                    appState.copyAndDismiss()
                } label: {
                    Label("Copy & Close", systemImage: "doc.on.doc.fill")
                }
                .keyboardShortcut(.return, modifiers: .command)

                Spacer()

                Button("Dismiss") {
                    appState.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .controlSize(.small)
        }
    }
}
