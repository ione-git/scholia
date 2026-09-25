import SwiftUI

enum Route: Hashable {
    case library
    case settings
}

#if DEBUG
    enum DebugRoute: Hashable {
        case tokenGallery
        case componentGallery
        case launchScreen
    }
#endif

struct RootView: View {
    @Environment(Settings.self) private var settings
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .library: LibraryView()
                    case .settings: SettingsView()
                    }
                }
                #if DEBUG
                    .navigationDestination(for: DebugRoute.self) { route in
                        switch route {
                        case .tokenGallery: TokenGallery()
                        case .componentGallery: ComponentGallery()
                        case .launchScreen: LaunchScreenPreview()
                        }
                    }
                #endif
        }
        .background {
            Color.clear.preferredColorScheme(settings.appTheme.colorScheme)
        }
    }
}

extension AppTheme {
    fileprivate var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
