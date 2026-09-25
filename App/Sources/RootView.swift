import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Scholia")
                    .accessibilityIdentifier("root.placeholder")
                #if DEBUG
                    NavigationLink("Token Gallery") { TokenGallery() }
                        .accessibilityIdentifier("root.tokenGallery")
                #endif
            }
        }
    }
}
