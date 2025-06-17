import SwiftUI

struct FullscreenWrapper<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .edgesIgnoringSafeArea(.all)
            .statusBar(hidden: true)
    }
}
