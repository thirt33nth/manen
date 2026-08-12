import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedMode: FocusMode = .focus
    @Published private(set) var isPlaying = false
    @Published private(set) var statusText = NSLocalizedString("status.tap_to_begin", comment: "")
    @Published private(set) var playbackElapsedText = "00:00:00"
    @Published private(set) var isProductivityPeriodsEnabled = false
    @Published private(set) var productivityCueStartedAt: Date?

    private let audioManager: AudioManager
    private var elapsedBeforeCurrentRun: TimeInterval = 0
    private var currentRunStartedAt: Date?
    private var focusPeriodStartedAt: Date?
    private var nextProductivityCueAt: TimeInterval = 25 * 60
    private var timerTask: Task<Void, Never>?

    private static let productivityPeriodDuration: TimeInterval = 25 * 60

    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        self.audioManager.onPlaybackStateChange = { [weak self] isPlaying in
            Task { @MainActor in
                self?.applyPlaybackState(isPlaying)
            }
        }

        #if DEBUG
        applyScreenshotLaunchConfigurationIfNeeded()
        #endif
    }

    func select(_ mode: FocusMode) {
        guard mode.isAvailableInMVP else { return }
        let didChangeMode = selectedMode != mode
        selectedMode = mode

        if isPlaying {
            do {
                if didChangeMode {
                    resetPlaybackTimer()
                    resetProductivityPeriod()
                }
                try audioManager.play(mode: selectedMode)
                applyPlaybackState(true)
            } catch {
                applyPlaybackError(error)
            }
        }
    }

    func setProductivityPeriodsEnabled(_ isEnabled: Bool) {
        isProductivityPeriodsEnabled = isEnabled

        if isEnabled {
            startProductivityPeriodIfNeeded()
        } else {
            resetProductivityPeriod()
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

        if playing {
            startPlaybackTimer()
            startProductivityPeriodIfNeeded()
        } else {
            pausePlaybackTimer()
            resetProductivityPeriod()
        }

        statusText = playing ? selectedMode.activeStatusText : NSLocalizedString("status.tap_to_begin", comment: "")
    }

    private func applyPlaybackError(_ error: Error) {
        resetPlaybackTimer()
        isPlaying = false
        statusText = NSLocalizedString("status.audio_unavailable", comment: "")
        audioManager.clearNowPlaying()
        debugPrint("Månen audio error:", error.localizedDescription)
    }

    private func startPlaybackTimer() {
        guard currentRunStartedAt == nil else { return }

        currentRunStartedAt = Date()
        updatePlaybackElapsedText()

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self?.updatePlaybackElapsedText()
                }
            }
        }
    }

    private func pausePlaybackTimer() {
        if let currentRunStartedAt {
            elapsedBeforeCurrentRun += Date().timeIntervalSince(currentRunStartedAt)
        }

        currentRunStartedAt = nil
        timerTask?.cancel()
        timerTask = nil
        updatePlaybackElapsedText()
    }

    private func resetPlaybackTimer() {
        elapsedBeforeCurrentRun = 0
        currentRunStartedAt = isPlaying ? Date() : nil
        updatePlaybackElapsedText()
    }

    private func updatePlaybackElapsedText() {
        let currentRunElapsed = currentRunStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let totalSeconds = max(0, Int(elapsedBeforeCurrentRun + currentRunElapsed))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        playbackElapsedText = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        evaluateProductivityPeriod()
    }

    private func startProductivityPeriodIfNeeded() {
        guard isProductivityPeriodsEnabled, isPlaying, selectedMode == .focus else {
            resetProductivityPeriod()
            return
        }

        if focusPeriodStartedAt == nil {
            focusPeriodStartedAt = Date()
            nextProductivityCueAt = Self.productivityPeriodDuration
        }
    }

    private func resetProductivityPeriod() {
        focusPeriodStartedAt = nil
        nextProductivityCueAt = Self.productivityPeriodDuration
        productivityCueStartedAt = nil
    }

    private func evaluateProductivityPeriod() {
        guard isProductivityPeriodsEnabled, isPlaying, selectedMode == .focus, let focusPeriodStartedAt else {
            return
        }

        let elapsed = Date().timeIntervalSince(focusPeriodStartedAt)
        guard elapsed >= nextProductivityCueAt else { return }

        triggerProductivityCue()
        let completedPeriods = floor(elapsed / Self.productivityPeriodDuration)
        nextProductivityCueAt = (completedPeriods + 1) * Self.productivityPeriodDuration
    }

    private func triggerProductivityCue() {
        productivityCueStartedAt = Date()

        do {
            try audioManager.playProductivityCue()
        } catch {
            debugPrint("Månen productivity cue error:", error.localizedDescription)
        }
    }

    deinit {
        timerTask?.cancel()
    }
}

#if DEBUG
private extension AppModel {
    func applyScreenshotLaunchConfigurationIfNeeded() {
        guard let rawState = ProcessInfo.processInfo.environment["MANEN_SCREENSHOT_STATE"] else {
            return
        }

        switch rawState {
        case "focus-idle":
            selectedMode = .focus
            isPlaying = false
            isProductivityPeriodsEnabled = false
            statusText = NSLocalizedString("status.tap_to_begin", comment: "")
            playbackElapsedText = "00:00:00"

        case "focus-active":
            applyScreenshotPlayingState(mode: .focus, elapsedSeconds: 8 * 60 + 42)

        case "relax-active":
            applyScreenshotPlayingState(mode: .relax, elapsedSeconds: 3 * 60 + 18)

        case "sleep-active":
            applyScreenshotPlayingState(mode: .sleep, elapsedSeconds: 12 * 60 + 7)

        case "productivity-cue":
            applyScreenshotPlayingState(mode: .focus, elapsedSeconds: 25 * 60)
            isProductivityPeriodsEnabled = true
            productivityCueStartedAt = Date()

        default:
            return
        }
    }

    func applyScreenshotPlayingState(mode: FocusMode, elapsedSeconds: TimeInterval) {
        selectedMode = mode
        isPlaying = true
        statusText = mode.activeStatusText
        elapsedBeforeCurrentRun = elapsedSeconds
        currentRunStartedAt = nil
        focusPeriodStartedAt = mode == .focus ? Date().addingTimeInterval(-elapsedSeconds) : nil
        nextProductivityCueAt = Self.productivityPeriodDuration
        updatePlaybackElapsedText()
    }
}
#endif
