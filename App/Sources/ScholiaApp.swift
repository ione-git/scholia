import DesignSystem
import SwiftData
import SwiftUI

@main
struct ScholiaApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    private let container: ModelContainer
    private let settings: Settings
    private let translationService: TranslationService

    init() {
        DesignSystem.registerFonts()
        if TestAnimations.areOff {
            UIView.setAnimationsEnabled(false)
        }
        do {
            let container = try Storage.makeContainer(.current)
            settings = try Storage.settings(in: container.mainContext)
            self.container = container
        } catch {
            fatalError("Storage: \(error)")
        }
        let provider: any TranslationProvider =
            if let mock = LaunchConfiguration.current.translation {
                MockTranslationProvider(isHeld: mock == .held)
            } else {
                AppleTranslationProvider()
            }
        translationService = TranslationService(provider: provider)
        ReadingReminder.schedule(for: settings)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(translationService)
                .environment(appDelegate.orientationLock)
                .transaction { transaction in
                    if TestAnimations.areOff {
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                    }
                }
                #if DEBUG
                    .background { LaunchDiagnostics(configuration: .current) }
                    .background { LibraryDiagnostics() }
                    .background { ReminderDiagnostics(settings: settings) }
                    .background { PrivacyDiagnostics() }
                    .background { AppearanceDiagnostics() }
                    .background { TranslationDiagnostics(provider: translationService.provider) }
                    .background { SafeAreaDiagnostics() }
                    .background { PasteboardDiagnostics() }
                #endif
        }
        .modelContainer(container)
    }
}
