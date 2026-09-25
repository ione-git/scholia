import DesignSystem
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .textStyle(.section)
            .foregroundStyle(.ink)
            .accessibilityIdentifier("settings.title")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.surface)
    }
}
