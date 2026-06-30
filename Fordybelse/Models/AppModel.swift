import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedMode: FocusMode = .focus
    @Published private(set) var isPlaying = false
    @Published private(set) var statusText = "Tap to begin"

    private let audioManager: AudioManager

    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        self.audioManager.onPlaybackStateChange = { [weak self] isPlaying in
            Task { @MainActor in
                self?.applyPlaybackState(isPlaying)
            }
        }
    }

    func select(_ mode: FocusMode) {
        guard mode.isAvailableInMVP else { return }
        selectedMode = mode

        if isPlaying {
            do {
                try audioManager.play(mode: selectedMode)
                applyPlaybackState(true)
            } catch {
                applyPlaybackError(error)
            }
        }
    }

    func togglePlayback() {
        do {
            if isPlaying {
                audioManager.pause()
                applyPlaybackState(false)
            } else {
                try audioManager.play(mode: selectedMode)
                applyPlaybackState(true)
            }
        } catch {
            applyPlaybackError(error)
        }
    }

    private func applyPlaybackState(_ playing: Bool) {
        isPlaying = playing
        statusText = playing ? "\(selectedMode.title) mode is active" : "Tap to begin"
    }

    private func applyPlaybackError(_ error: Error) {
        isPlaying = false
        statusText = "Audio asset unavailable"
        audioManager.clearNowPlaying()
        debugPrint("Lugna audio error:", error.localizedDescription)
    }
}
