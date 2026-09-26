import SwiftUI

enum Route: Hashable {
    case library
    case settings
    case reader(Book)
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
    @State private var isPickingFile = false

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path, isPickingFile: $isPickingFile)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .library: LibraryView()
                    case .settings: SettingsView()
                    case .reader(let book): ReadingView(book: book)
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
        .modifier(ImportFlow(isPickingFile: $isPickingFile))
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
