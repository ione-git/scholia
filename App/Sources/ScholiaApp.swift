import SwiftUI

@main
struct ScholiaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                #if DEBUG
                    .background { LaunchDiagnostics(configuration: .current) }
                #endif
        }
    }
}
