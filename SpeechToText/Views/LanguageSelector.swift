import SwiftUI

struct LanguageSelector: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            ForEach(LanguageMode.allCases, id: \.self) { mode in
                Button {
                    appState.selectedLanguage = mode
                } label: {
                    Text(mode.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(appState.selectedLanguage == mode
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.2))
                        )
                        .foregroundColor(appState.selectedLanguage == mode ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
