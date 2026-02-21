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

            HStack {
                Button {
                    appState.copyToClipboard()
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied!" : "Copy",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: .command)

                Spacer()

                Button("Dismiss") {
                    appState.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
    }
}
