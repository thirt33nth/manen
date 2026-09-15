import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

final class AudioManager: NSObject {
    enum AudioError: LocalizedError {
        case missingAsset(String)

        var errorDescription: String? {
            switch self {
        case .missingAsset(let name):
                return "Missing bundled audio asset: \(name)"
            }
        }
    }

    var onPlaybackStateChange: ((Bool) -> Void)?

    private var player: AVAudioPlayer?
    private var productivityCuePlayer: AVAudioPlayer?
    private var activeMode: FocusMode?
    private var didConfigureRemoteCommands = false

    func play(mode: FocusMode) throws {
        try configureAudioSession()
        try loadPlayerIfNeeded(for: mode)

        player?.numberOfLoops = -1
        player?.prepareToPlay()
        player?.play()

        activeMode = mode
        updateNowPlaying(isPlaying: true)
        configureRemoteCommandsIfNeeded()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        onPlaybackStateChange?(true)
    }

    func pause() {
        player?.pause()
        updateNowPlaying(isPlaying: false)
        onPlaybackStateChange?(false)
    }

    func playProductivityCue() throws {
        try configureAudioSession()

        guard let url = Bundle.main.url(forResource: "productivity_cue", withExtension: "m4a") else {
            throw AudioError.missingAsset("productivity_cue.m4a")
        }

        productivityCuePlayer = try AVAudioPlayer(contentsOf: url)
        productivityCuePlayer?.numberOfLoops = 0
        productivityCuePlayer?.volume = 0.42
        productivityCuePlayer?.prepareToPlay()
        productivityCuePlayer?.play()
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func loadPlayerIfNeeded(for mode: FocusMode) throws {
        if activeMode == mode, player != nil {
            return
        }

        guard let url = Bundle.main.url(forResource: mode.audioFileName, withExtension: mode.audioFileExtension) else {
            throw AudioError.missingAsset("\(mode.audioFileName).\(mode.audioFileExtension)")
        }

        player = try AVAudioPlayer(contentsOf: url)
        activeMode = mode
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    private func configureRemoteCommandsIfNeeded() {
        guard !didConfigureRemoteCommands else { return }
        didConfigureRemoteCommands = true

        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self, let mode = self.activeMode else { return .commandFailed }
            do {
                try self.play(mode: mode)
                return .success
            } catch {
                return .commandFailed
            }
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.player?.isPlaying == true {
                self.pause()
            } else if let mode = self.activeMode {
                do {
                    try self.play(mode: mode)
                } catch {
                    return .commandFailed
                }
            }
            return .success
        }
    }

    private func updateNowPlaying(isPlaying: Bool) {
        let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 512, height: 512)) { _ in
            Self.placeholderArtwork()
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Månen",
            MPMediaItemPropertyArtist: "Månen",
            MPMediaItemPropertyAlbumTitle: String(
                format: NSLocalizedString("now_playing.album_format", comment: ""),
                activeMode?.title ?? FocusMode.focus.title
            ),
            MPMediaItemPropertyPlaybackDuration: player?.duration ?? 0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player?.currentTime ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyArtwork: artwork
        ]
    }

    private static func placeholderArtwork() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(white: 0.94, alpha: 1).setFill()
            context.fill(rect)

            UIColor(white: 0.08, alpha: 0.10).setFill()
            UIBezierPath(ovalIn: CGRect(x: 142, y: 112, width: 228, height: 288)).fill()

            UIColor(white: 0.08, alpha: 0.68).setFill()
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "HelveticaNeue-Light", size: 38) ?? UIFont.systemFont(ofSize: 38, weight: .light),
                .foregroundColor: UIColor(white: 0.08, alpha: 0.72),
                .paragraphStyle: paragraph
            ]
            "Månen".draw(in: CGRect(x: 0, y: 226, width: 512, height: 64), withAttributes: attributes)
        }
    }
}
