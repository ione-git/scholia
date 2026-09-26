import DesignSystem
import SwiftUI

struct ReaderSettingsSheet: View {
    var body: some View {
        Color.clear
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("readerSettings.sheet")
            .presentationDetents([.medium])
            .glassSheetStyle()
    }
}
