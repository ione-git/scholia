import DesignSystem
import SwiftData
import SwiftUI

@main
struct ScholiaApp: App {
    private let container: ModelContainer
    private let settings: Settings

    init() {
        DesignSystem.registerFonts()
        do {
            let container = try Storage.makeContainer(.current)
            settings = try Storage.settings(in: container.mainContext)
            self.container = container
        } catch {
            fatalError("Storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                #if DEBUG
                    .background { LaunchDiagnostics(configuration: .current) }
                    .background { LibraryDiagnostics() }
                    .background { ReadingDiagnostics() }
                #endif
        }
        .modelContainer(container)
    }
}
