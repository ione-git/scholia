import DesignSystem
import SwiftUI

nonisolated enum BookLanguage {
    static func code(from identifier: String) -> String? {
        Locale.Language(identifier: identifier).languageCode?.identifier
    }

    static func name(of code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code) ?? code
    }

    private static let all = Locale.LanguageCode.isoLanguageCodes.map(\.identifier)
        .filter { $0.count == 2 }
        .map { (code: $0, name: name(of: $0)) }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        .map(\.code)

    static func codes(detected: String?) -> [String] {
        guard let detected else { return all }
        return [detected] + all.filter { $0 != detected }
    }
}

extension Text {
    init(language code: String, isDetected: Bool) {
        let name = BookLanguage.name(of: code)
        if isDetected {
            let detected = Text("· detected").font(TextStyle.caption.font).foregroundStyle(Color.inkMuted)
            self.init("\(name) \(detected)")
        } else {
            self.init(name)
        }
    }
}

struct LanguagePicker: View {
    @Binding var selection: String?
    let detected: String?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        VStack(spacing: .space4) {
            SheetHeader(Text("Language")) {
                Button("Back") { dismiss() }
                    .buttonStyle(.sheetBack)
                    .accessibilityIdentifier("languagePicker.back")
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: .space5) {
                    SearchField(text: $query, prompt: Text("Search"), label: Text("Search languages"))
                        .accessibilityIdentifier("languagePicker.searchField")
                    Text(
                        "The book’s language decides how words are read and translated. Detected from the file; change it if it looks wrong."
                    )
                    .textStyle(.caption)
                    .foregroundStyle(.inkMuted)
                    .padding(.horizontal, .space1)
                    if !matches.isEmpty {
                        GroupedList {
                            ForEach(matches, id: \.self) { code in
                                row(code)
                            }
                        }
                    }
                }
                .padding(.bottom, .space10)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(.horizontal, .space5)
        .padding(.top, .space7)
        .background(.surface)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var matches: [String] {
        let codes = BookLanguage.codes(detected: detected)
        guard !query.isEmpty else { return codes }
        return codes.filter { BookLanguage.name(of: $0).localizedStandardContains(query) }
    }

    private func row(_ code: String) -> some View {
        Button {
            selection = code
            dismiss()
        } label: {
            ListRow(Text(language: code, isDetected: code == detected), height: .regular) {
                if code == selection {
                    ListRowCheckmark()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(code == selection ? .isSelected : [])
        .accessibilityIdentifier("languagePicker.language.\(code)")
    }
}
