import SwiftUI

struct ProductivityPeriodsToggle: View {
    let isEnabled: Bool
    let isCompact: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle(
            isOn: Binding(
                get: { isEnabled },
                set: onChange
            )
        ) {
            VStack(alignment: .leading, spacing: 3) {
                Text("productivity_periods.title")
                    .font(.custom("HelveticaNeue-Light", size: isCompact ? 13 : 14))
                    .foregroundStyle(.primary.opacity(0.84))

                Text(subtitleKey)
                    .font(.custom("HelveticaNeue-Light", size: isCompact ? 10 : 11))
                    .foregroundStyle(.secondary.opacity(0.64))
            }
        }
        .toggleStyle(.switch)
        .tint(Color.primary.opacity(0.86))
        .padding(.top, isCompact ? 13 : 15)
        .accessibilityLabel(Text("productivity_periods.accessibility.label"))
        .accessibilityHint(Text("productivity_periods.accessibility.hint"))
    }

    private var subtitleKey: LocalizedStringKey {
        isEnabled ? "productivity_periods.subtitle.enabled" : "productivity_periods.subtitle.disabled"
    }
}
