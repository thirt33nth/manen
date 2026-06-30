import SwiftUI

struct PlayPauseButton: View {
    let isPlaying: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(buttonFill)
                    .frame(width: 88, height: 88)
                    .shadow(color: shadowColor, radius: isPlaying ? 14 : 10, y: isPlaying ? 8 : 5)
                    .overlay {
                        Circle()
                            .strokeBorder(borderColor, lineWidth: 1)
                    }

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(iconColor)
                    .offset(x: isPlaying ? 0 : 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause focus soundscape" : "Play focus soundscape")
        .accessibilityHint("Starts or pauses Lugna")
        .animation(.easeInOut(duration: 0.55), value: isPlaying)
    }

    private var buttonFill: Color {
        colorScheme == .dark
            ? Color(white: 0.10).opacity(0.96)
            : Color(white: 0.985).opacity(0.98)
    }

    private var iconColor: Color {
        colorScheme == .dark
            ? Color(white: 0.90)
            : Color(white: 0.08)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.13)
            : Color.black.opacity(0.10)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.38)
            : Color.black.opacity(0.10)
    }
}
