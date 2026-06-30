import SwiftUI

@main
struct FordybelseApp: App {
    @StateObject private var appModel = AppModel(audioManager: AudioManager())

    var body: some Scene {
        WindowGroup {
            HomeView(model: appModel)
        }
    }
}
