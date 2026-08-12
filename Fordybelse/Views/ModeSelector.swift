import SwiftUI

struct ModeSelector: View {
    let selectedMode: FocusMode
    let onSelect: (FocusMode) -> Void

    var body: some View {
        HStack(spacing: 32) {
            ForEach(FocusMode.allCases) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    ModeIcon(
                        mode: mode,
                        isSelected: mode == selectedMode,
                        isAvailable: mode.isAvailableInMVP
                    )
                }
                .buttonStyle(.plain)
                .disabled(!mode.isAvailableInMVP)
                .accessibilityLabel(accessibilityLabel(for: mode))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedMode)
    }

    private func accessibilityLabel(for mode: FocusMode) -> String {
        let key = mode.isAvailableInMVP ? "mode.accessibility.available" : "mode.accessibility.coming_later"
        return String(format: NSLocalizedString(key, comment: ""), mode.title)
    }
}

private struct ModeIcon: View {
    let mode: FocusMode
    let isSelected: Bool
    let isAvailable: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.primary.opacity(0.055))
                    .frame(width: 66, height: 66)

                Arc()
                    .stroke(Color.primary.opacity(0.30), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(34))
                    .offset(y: 1)

                Capsule()
                    .fill(Color.primary.opacity(0.34))
                    .frame(width: 68, height: 1)
                    .offset(y: 38)
            }

            Image(systemName: mode.iconName)
                .font(.system(size: mode.iconSize, weight: isSelected ? .regular : .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(foreground)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .frame(width: 68, height: 82)
    }

    private var foreground: Color {
        guard isAvailable else {
            return .secondary.opacity(0.28)
        }

        return isSelected ? .primary.opacity(0.90) : .secondary.opacity(0.64)
    }
}

private struct Arc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) * 0.43
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: radius,
            startAngle: .degrees(42),
            endAngle: .degrees(138),
            clockwise: false
        )
        return path
    }
}

private extension FocusMode {
    var iconName: String {
        switch self {
        case .focus:
            return "scope"
        case .relax:
            return "water.waves"
        case .sleep:
            return "moon.fill"
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .focus:
            return 21
        case .relax:
            return 22
        case .sleep:
            return 24
        }
    }
}
