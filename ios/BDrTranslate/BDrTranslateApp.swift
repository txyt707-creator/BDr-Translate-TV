import SwiftUI

@main
struct BDrTranslateApp: App {
    @StateObject private var relay = SubtitleRelay()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(relay)
        }
    }
}
