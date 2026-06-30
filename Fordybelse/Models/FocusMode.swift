import Foundation

enum FocusMode: String, CaseIterable, Identifiable {
    case focus
    case relax
    case sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus:
            return "Focus"
        case .relax:
            return "Relax"
        case .sleep:
            return "Sleep"
        }
    }

    var audioFileName: String {
        switch self {
        case .focus:
            return "focus_loop"
        case .relax:
            return "relax_loop"
        case .sleep:
            return "sleep_loop"
        }
    }

    var audioFileExtension: String {
        "wav"
    }

    var isAvailableInMVP: Bool {
        true
    }
}
