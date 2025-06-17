import SwiftUI

@main
struct AnonycordApp: App {
    var body: some Scene {
        WindowGroup {
            FullscreenWrapper {
                RecordView()
            }
        }
    }
}
