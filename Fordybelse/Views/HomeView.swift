import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let usableHeight = proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom
            let compact = usableHeight < 720

            ZStack {
                AmbientBackdrop(isActive: model.isPlaying)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header(compact: compact)
                        .padding(.top, compact ? 14 : 20)
                        .padding(.horizontal, compact ? 22 : 28)

                    ModeSelector(selectedMode: model.selectedMode) { mode in
                        model.select(mode)
                    }
                    .padding(.top, compact ? 16 : 20)
                    .padding(.horizontal, compact ? 22 : 28)

                    ZStack(alignment: .bottom) {
                        GenerativeAnimationStage(isActive: model.isPlaying, mode: model.selectedMode)
                            .padding(.horizontal, compact ? 10 : 14)
                            .padding(.top, compact ? 10 : 16)
                            .padding(.bottom, compact ? 54 : 64)

                        bottomReadabilityOverlay
                            .frame(height: compact ? 112 : 132)

                        VStack(spacing: 0) {
                            Spacer(minLength: compact ? 24 : 34)

                            PlayPauseButton(isPlaying: model.isPlaying) {
                                model.togglePlayback()
                            }

                            Spacer(minLength: compact ? 24 : 34)

                            VStack(spacing: compact ? 4 : 5) {
                                Text("Your personal soundscape.")
                                    .font(.custom("HelveticaNeue-Light", size: compact ? 12 : 13))
                                    .foregroundStyle(.secondary.opacity(0.74))

                                Text("Version \(appVersion)")
                                    .font(.custom("HelveticaNeue-Light", size: compact ? 10 : 11))
                                    .foregroundStyle(.secondary.opacity(0.48))
                            }
                            .padding(.bottom, compact ? 12 : 18)
                        }
                        .padding(.horizontal, compact ? 22 : 28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .preferredColorScheme(nil)
    }

    private func header(compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 8) {
            Text("Lugna")
                .font(.custom("HelveticaNeue-Thin", size: compact ? 31 : 34))
                .tracking(0)
                .foregroundStyle(primaryText)

            Text(model.statusText)
                .font(.custom("HelveticaNeue-Light", size: compact ? 13 : 14))
                .foregroundStyle(.secondary.opacity(0.82))
                .contentTransition(.opacity)
        }
        .animation(.easeInOut(duration: 0.35), value: model.statusText)
    }

    private var primaryText: Color {
        colorScheme == .dark ? Color(white: 0.92) : Color(white: 0.08)
    }

    private var bottomReadabilityOverlay: some View {
        LinearGradient(
            colors: [
                backgroundColor.opacity(0),
                backgroundColor.opacity(0.72),
                backgroundColor
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.035) : Color(white: 0.965)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
