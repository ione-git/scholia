import DesignSystem
import SwiftUI

@main
struct ScholiaApp: App {
    init() {
        DesignSystem.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                #if DEBUG
                    .background { LaunchDiagnostics(configuration: .current) }
                #endif
        }
    }
}
