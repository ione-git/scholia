import DesignSystem
import SwiftData
import SwiftUI

@main
struct ScholiaApp: App {
    private let container: ModelContainer

    init() {
        DesignSystem.registerFonts()
        do {
            container = try Storage.makeContainer(.current)
        } catch {
            fatalError("Storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                #if DEBUG
                    .background { LaunchDiagnostics(configuration: .current) }
                    .background { LibraryDiagnostics() }
                #endif
        }
        .modelContainer(container)
    }
}
