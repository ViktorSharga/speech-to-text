import SwiftUI

struct RecordingIndicator: View {
    let level: Float

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer ring — audio level
            Circle()
                .stroke(Color.red.opacity(0.3), lineWidth: 3)
                .frame(width: 70, height: 70)
                .scaleEffect(1.0 + CGFloat(level) * 0.4)
                .animation(.easeOut(duration: 0.1), value: level)

            // Pulsing background
            Circle()
                .fill(Color.red.opacity(0.15))
                .frame(width: 60, height: 60)
                .scaleEffect(isPulsing ? 1.1 : 0.95)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)

            // Mic icon
            Image(systemName: "mic.fill")
                .font(.system(size: 28))
                .foregroundColor(.red)
        }
        .onAppear {
            isPulsing = true
        }
    }
}
