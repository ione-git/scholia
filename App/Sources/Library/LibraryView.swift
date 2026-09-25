import DesignSystem
import SwiftUI

struct LibraryView: View {
    var body: some View {
        Text("Library")
            .textStyle(.section)
            .foregroundStyle(.ink)
            .accessibilityIdentifier("library.title")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.surface)
    }
}
