import Foundation

enum FocusMode: String, CaseIterable, Identifiable {
    case focus
    case relax
    case sleep

    var id: String { rawValue }

    var title: String {
        NSLocalizedString(titleLocalizationKey, comment: "")
    }

    var activeStatusText: String {
        NSLocalizedString(activeStatusLocalizationKey, comment: "")
    }

    var titleLocalizationKey: String {
        switch self {
        case .focus:
            return "mode.focus.title"
        case .relax:
            return "mode.relax.title"
        case .sleep:
            return "mode.sleep.title"
        }
    }

    private var activeStatusLocalizationKey: String {
        switch self {
        case .focus:
            return "status.focus_active"
        case .relax:
            return "status.relax_active"
        case .sleep:
            return "status.sleep_active"
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
        "m4a"
    }

    var isAvailableInMVP: Bool {
        true
    }
}
