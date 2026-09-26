#if DEBUG
    import DesignSystem
    import SwiftUI

    struct ComponentGallery: View {
        enum Appearance: Hashable {
            case system
            case light
            case dark

            var colorScheme: ColorScheme? {
                switch self {
                case .system: nil
                case .light: .light
                case .dark: .dark
                }
            }
        }

        @State private var appearance = Appearance.system

        var body: some View {
            GalleryPage(identifier: "componentGallery", colorScheme: appearance.colorScheme) {
                GroupedSection(Text("Appearance")) {
                    ListRow(Text("Theme"), height: .control) {
                        SegmentedControl(
                            selection: $appearance, size: .compact,
                            segments: [
                                .init(
                                    .system, title: Text("System"), count: nil, identifier: "componentGallery.system"),
                                .init(.light, title: Text("Light"), count: nil, identifier: "componentGallery.light"),
                                .init(.dark, title: Text("Dark"), count: nil, identifier: "componentGallery.dark"),
                            ])
                    }
                }
                GroupedSection(Text("Components")) {
                    link(Text("Glass button"), element: "glassButton") {
                        GlassButtonGallery(colorScheme: appearance.colorScheme)
                    }
                    link(Text("Chip"), element: "chip") { ChipGallery(colorScheme: appearance.colorScheme) }
                    link(Text("Book cover"), element: "bookCover") {
                        BookCoverGallery(colorScheme: appearance.colorScheme)
                    }
                    link(Text("List rows"), element: "listRows") { ListRowGallery(colorScheme: appearance.colorScheme) }
                    link(Text("Segmented control"), element: "segmentedControl") {
                        SegmentedControlGallery(colorScheme: appearance.colorScheme)
                    }
                    link(Text("Sheets and popover"), element: "presentations") {
                        PresentationGallery(colorScheme: appearance.colorScheme)
                    }
                    link(Text("Selection and toolbar"), element: "selection") {
                        SelectionGallery(colorScheme: appearance.colorScheme)
                    }
                    link(Text("Glass menu"), element: "glassMenu") {
                        GlassMenuGallery(colorScheme: appearance.colorScheme)
                    }
                }
            }
            .navigationTitle("Component Gallery")
        }

        private func link(_ title: Text, element: String, @ViewBuilder destination: () -> some View) -> some View {
            NavigationLink(destination: destination) {
                ListRow(title, height: .regular) { ListRowChevron() }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("componentGallery.\(element)")
        }
    }

    private struct GalleryPage<Content: View>: View {
        let identifier: String
        let colorScheme: ColorScheme?
        @ViewBuilder let content: Content

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: .space6) { content }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .space5)
                    .padding(.bottom, .space10)
            }
            .accessibilityIdentifier("\(identifier).scrollView")
            .modifier(AppearanceValue())
            .background(.surface)
            .foregroundStyle(.ink)
            .preferredColorScheme(colorScheme)
        }
    }

    private struct AppearanceValue: ViewModifier {
        @Environment(\.colorScheme) private var colorScheme

        func body(content: Content) -> some View {
            content.accessibilityValue(Text(verbatim: colorScheme == .dark ? "dark" : "light"))
        }
    }

    private struct GlassButtonGallery: View {
        let colorScheme: ColorScheme?
        @State private var isMenuOpen = true
        @State private var isReaderMenuOpen = false

        var body: some View {
            GalleryPage(identifier: "glassButtonGallery", colorScheme: colorScheme) {
                HStack(spacing: .space4) {
                    button(.back, label: Text("Back"), element: "back", size: .regular, isActive: false) {}
                    button(.add, label: Text("Add a book"), element: "add", size: .regular, isActive: false) {}
                    button(.bookmark, label: Text("Bookmark"), element: "bookmark", size: .regular, isActive: false) {}
                    button(.more, label: Text("Menu"), element: "menu", size: .regular, isActive: isMenuOpen) {
                        isMenuOpen.toggle()
                    }
                }
                .padding(.space5)
                .background(.surfacePaper, in: RoundedRectangle(cornerRadius: .radiusLg))
                HStack(spacing: .space2) {
                    button(.back, label: Text("Back"), element: "chromeBack", size: .regular, isActive: false) {}
                    StackedTitle(
                        title: Text(verbatim: "Die Verwandlung"), subtitle: Text(verbatim: "Franz Kafka · Erster Teil"),
                        titleIdentifier: "glassButtonGallery.stackedTitle.title",
                        subtitleIdentifier: "glassButtonGallery.stackedTitle.subtitle"
                    )
                    .frame(maxWidth: .infinity)
                    button(
                        .bookmarkFilled, label: Text("Bookmarked. Remove bookmark"), element: "bookmarkFilled",
                        size: .regular, isActive: false
                    ) {}
                }
                .padding(.space4)
                .background(.surfacePaper, in: RoundedRectangle(cornerRadius: .radiusLg))
                HStack(spacing: .space4) {
                    button(
                        .bookmark, label: Text("Bookmark"), element: "readerBookmark", size: .reader, isActive: false
                    ) {}
                    button(.more, label: Text("Menu"), element: "readerMenu", size: .reader, isActive: isReaderMenuOpen)
                    {
                        isReaderMenuOpen.toggle()
                    }
                }
                .padding(.space5)
                .background(.surfacePaper, in: RoundedRectangle(cornerRadius: .radiusLg))
            }
            .navigationTitle("Glass button")
        }

        private func button(
            _ icon: Icon, label: Text, element: String, size: GlassButton.Size, isActive: Bool,
            action: @escaping () -> Void
        ) -> some View {
            GlassButton(icon, label: label, size: size, isActive: isActive, action: action)
                .accessibilityIdentifier("glassButtonGallery.\(element)")
        }
    }

    private struct ChipGallery: View {
        let colorScheme: ColorScheme?
        @State private var selected = "All"
        @State private var collections = [("Biographies", 4), ("Fiction", 11)]

        var body: some View {
            GalleryPage(identifier: "chipGallery", colorScheme: colorScheme) {
                ScrollView(.horizontal) {
                    HStack(spacing: .space2) {
                        chip(Text("All"), key: "All", count: 24)
                        ForEach(collections, id: \.0) { name, count in
                            chip(Text(name), key: name, count: count)
                        }
                        NewCollectionChip(label: Text("New collection")) {
                            collections.append((String(localized: "Collection \(collections.count + 1)"), 0))
                        }
                        .accessibilityIdentifier("chipGallery.newCollection")
                    }
                    .padding(.vertical, .space5)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
            .navigationTitle("Chip")
        }

        private func chip(_ title: Text, key: String, count: Int) -> some View {
            Chip(title, count: count, isSelected: selected == key) { selected = key }
                .accessibilityIdentifier("chipGallery.chip.\(key)")
        }
    }

    private struct BookCoverGallery: View {
        let colorScheme: ColorScheme?

        var body: some View {
            GalleryPage(identifier: "bookCoverGallery", colorScheme: colorScheme) {
                HStack(alignment: .top, spacing: .space4) {
                    cover(
                        "Die Verwandlung", author: "Franz Kafka", color: 0x2E3A4F, image: nil, size: .hero,
                        isFinished: false)
                    cover(
                        "Solaris", author: "Stanisław Lem", color: 0x35545E, image: nil, size: .library,
                        isFinished: false)
                    cover("Thumbnail", author: nil, color: 0x8A6D2F, image: nil, size: .thumbnail, isFinished: false)
                }
                HStack(alignment: .top, spacing: .space4) {
                    cover(
                        "Il nome della rosa", author: "Umberto Eco", color: 0x6B2F3A, image: nil, size: .row,
                        isFinished: false)
                    cover(
                        "Educated", author: "Tara Westover", color: 0x8A6D2F, image: nil, size: .grid, isFinished: false
                    )
                    cover(
                        "L’Étranger", author: "Albert Camus", color: 0x9A6B4E, image: nil, size: .library,
                        isFinished: true
                    )
                }
                HStack(alignment: .top, spacing: .space4) {
                    VStack(spacing: .space4) {
                        cover(
                            "Der Prozess", author: "Franz Kafka", color: 0x2E3A4F, image: nil, size: .heroLarge,
                            isFinished: false)
                        ProgressBar(value: 0.4)
                            .frame(width: BookCover.Size.heroLarge.width)
                            .accessibilityIdentifier("bookCoverGallery.progress")
                    }
                    cover("Image", author: nil, color: 0x2F5D50, image: sampleImage, size: .library, isFinished: false)
                }
            }
            .navigationTitle("Book cover")
        }

        private var sampleImage: Image {
            let size = BookCover.Size.library
            let renderer = ImageRenderer(
                content: LinearGradient(colors: [.accent, .ink], startPoint: .top, endPoint: .bottom)
                    .frame(width: size.width, height: size.height)
                    .environment(\.colorScheme, .light))
            return Image(uiImage: renderer.uiImage ?? UIImage())
        }

        private func cover(
            _ title: String, author: String?, color: UInt32, image: Image?, size: BookCover.Size,
            isFinished: Bool
        ) -> some View {
            BookCover(
                title: title, author: author, color: Color(hex: color), image: image, size: size,
                isFinished: isFinished, finishedValue: Text("Finished")
            )
            .accessibilityIdentifier("bookCoverGallery.cover.\(title)")
        }
    }

    private struct ListRowGallery: View {
        let colorScheme: ColorScheme?
        @State private var onWordTap = "bubble"
        @State private var goal = 20
        @State private var isFictionChecked = true

        var body: some View {
            GalleryPage(identifier: "listRowGallery", colorScheme: colorScheme) {
                GroupedSection(Text("Translation")) {
                    ListRow(Text("Translate to"), height: .regular) { ListRowValue(Text("Russian")) }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("listRowGallery.translateTo")
                    ListRow(Text("On word tap"), height: .control) {
                        SegmentedControl(
                            selection: $onWordTap, size: .compact,
                            segments: [
                                .init("bubble", title: Text("Bubble"), count: nil, identifier: "listRowGallery.bubble"),
                                .init(
                                    "minimal", title: Text("Minimal"), count: nil, identifier: "listRowGallery.minimal"),
                                .init("card", title: Text("Card"), count: nil, identifier: "listRowGallery.card"),
                            ])
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("listRowGallery.onWordTap")
                }
                GroupedSection(Text("Reading")) {
                    Button {
                        goal += 5
                    } label: {
                        ListRow(Text("Daily goal"), height: .regular) { ListRowValue(Text("\(goal) min")) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("listRowGallery.dailyGoal")
                }
                GroupedList {
                    Button {
                        isFictionChecked.toggle()
                    } label: {
                        ListRow(Text("Fiction"), height: .regular) { ListRowCheckbox(isChecked: isFictionChecked) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isFictionChecked ? .isSelected : [])
                    .accessibilityIdentifier("listRowGallery.checkbox")
                }
                GroupedList {
                    Button {
                    } label: {
                        ListActionRow(Text("New Collection…"), icon: .add)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("listRowGallery.action")
                }
            }
            .navigationTitle("List rows")
        }
    }

    private struct SegmentedControlGallery: View {
        enum Tab: Hashable {
            case contents
            case highlights
            case bookmarks
        }

        let colorScheme: ColorScheme?
        @State private var tab = Tab.contents
        @State private var onWordTap = "bubble"

        var body: some View {
            GalleryPage(identifier: "segmentedControlGallery", colorScheme: colorScheme) {
                SegmentedControl(
                    selection: $tab, size: .regular,
                    segments: [
                        .init(
                            .contents, title: Text("Contents"), count: nil,
                            identifier: "segmentedControlGallery.contents"),
                        .init(
                            .highlights, title: Text("Highlights"), count: 3,
                            identifier: "segmentedControlGallery.highlights"),
                        .init(
                            .bookmarks, title: Text("Bookmarks"), count: 2,
                            identifier: "segmentedControlGallery.bookmarks"),
                    ])
                SegmentedControl(
                    selection: $onWordTap, size: .compact,
                    segments: [
                        .init(
                            "bubble", title: Text("Bubble"), count: nil, identifier: "segmentedControlGallery.bubble"),
                        .init(
                            "minimal", title: Text("Minimal"), count: nil, identifier: "segmentedControlGallery.minimal"
                        ),
                        .init("card", title: Text("Card"), count: nil, identifier: "segmentedControlGallery.card"),
                    ])
            }
            .navigationTitle("Segmented control")
        }
    }

    private struct PresentationGallery: View {
        let colorScheme: ColorScheme?
        @State private var isModalSheetShown = false
        @State private var isGlassSheetShown = false
        @State private var isPopoverShown = false
        @State private var pageTurn = "slide"

        var body: some View {
            GalleryPage(identifier: "presentationGallery", colorScheme: colorScheme) {
                GroupedList {
                    row(Text("Modal sheet"), element: "modalSheet") { isModalSheetShown = true }
                    row(Text("Glass sheet"), element: "glassSheet") { isGlassSheetShown = true }
                    row(Text("Popover"), element: "popover") { isPopoverShown = true }
                        .popover(isPresented: $isPopoverShown) {
                            Text("6 min to go")
                                .textStyle(.title3)
                                .foregroundStyle(.ink)
                                .padding(.space4)
                                .accessibilityIdentifier("galleryPopover.text")
                                .modifier(AppearanceValue())
                                .popoverStyle()
                        }
                }
            }
            .navigationTitle("Sheets and popover")
            .modalSheet(isPresented: $isModalSheetShown) {
                VStack(spacing: .space4) {
                    SheetHeader(Text("Add to Collection")) {
                        Button("Cancel") { isModalSheetShown = false }
                            .buttonStyle(.sheetCancel)
                            .accessibilityIdentifier("galleryModalSheet.cancel")
                    } trailing: {
                        Button("Done") { isModalSheetShown = false }
                            .buttonStyle(.sheetDone)
                            .accessibilityIdentifier("galleryModalSheet.done")
                    }
                    GroupedList {
                        ListRow(Text("Science Fiction"), height: .regular) {}
                        ListRow(Text("Biographies"), height: .regular) {}
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, .space5)
                .padding(.top, .space4)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("galleryModalSheet.content")
                .modifier(AppearanceValue())
            }
            .sheet(isPresented: $isGlassSheetShown) {
                VStack(spacing: .space4) {
                    SheetHeader(Text("Themes & Settings")) {
                        EmptyView()
                    } trailing: {
                        Button("Done") { isGlassSheetShown = false }
                            .buttonStyle(.sheetDone)
                            .accessibilityIdentifier("galleryGlassSheet.done")
                    }
                    SegmentedControl(
                        selection: $pageTurn, size: .regular,
                        segments: [
                            .init("slide", title: Text("Slide"), count: nil, identifier: "galleryGlassSheet.slide"),
                            .init("curl", title: Text("Curl"), count: nil, identifier: "galleryGlassSheet.curl"),
                            .init("fade", title: Text("Fade"), count: nil, identifier: "galleryGlassSheet.fade"),
                            .init("scroll", title: Text("Scroll"), count: nil, identifier: "galleryGlassSheet.scroll"),
                        ])
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, .space5)
                .padding(.top, .space4)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("galleryGlassSheet.content")
                .modifier(AppearanceValue())
                .presentationDetents([.medium])
                .glassSheetStyle()
            }
        }

        private func row(_ title: Text, element: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                ListRow(title, height: .regular) { ListRowChevron() }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("presentationGallery.\(element)")
        }
    }

    private struct SelectionGallery: View {
        let colorScheme: ColorScheme?
        @State private var selected: Set<String> = ["Solaris"]

        var body: some View {
            GalleryPage(identifier: "selectionGallery", colorScheme: colorScheme) {
                HStack(alignment: .top, spacing: .space4) {
                    cover("Solaris", color: 0x35545E)
                    cover("Educated", color: 0x8A6D2F)
                }
                GlassToolbar {
                    GlassToolbarItem(Text("Collection"), icon: .collection, role: nil) {}
                        .accessibilityIdentifier("selectionGallery.collection")
                    GlassToolbarItem(Text("Finished"), icon: .select, role: nil) {}
                        .accessibilityIdentifier("selectionGallery.finished")
                    GlassToolbarItem(Text("Remove"), icon: .trash, role: .destructive) {}
                        .accessibilityIdentifier("selectionGallery.remove")
                }
                .disabled(selected.isEmpty)
            }
            .navigationTitle("Selection and toolbar")
        }

        private func cover(_ title: String, color: UInt32) -> some View {
            let isSelected = selected.contains(title)
            return Button {
                if selected.remove(title) == nil {
                    selected.insert(title)
                }
            } label: {
                BookCover(
                    title: title, author: nil, color: Color(hex: color), image: nil, size: .library, isFinished: false,
                    finishedValue: Text("Finished")
                )
                .selectable(isSelected: isSelected)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("selectionGallery.cover.\(title)")
        }
    }

    private struct GlassMenuGallery: View {
        let colorScheme: ColorScheme?

        var body: some View {
            GalleryPage(identifier: "glassMenuGallery", colorScheme: colorScheme) {
                GlassMenu(size: .reader) {
                    item(Text("Contents"), icon: .contents, element: "contents")
                    item(Text("Highlights"), icon: .highlighter, element: "highlights")
                    item(Text("Bookmarks"), icon: .bookmark, element: "bookmarks")
                    GlassMenuDivider()
                    GlassMenuItem(Text("Themes & Settings"), sample: Text(verbatim: "Aa")) {}
                        .accessibilityIdentifier("glassMenuGallery.settings")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .space5)
                .background(.surfacePaper, in: RoundedRectangle(cornerRadius: .radiusLg))
            }
            .navigationTitle("Glass menu")
        }

        private func item(_ title: Text, icon: Icon, element: String) -> some View {
            GlassMenuItem(title, icon: icon) {}
                .accessibilityIdentifier("glassMenuGallery.\(element)")
        }
    }

    extension Color {
        fileprivate init(hex: UInt32) {
            self.init(
                red: Double(hex >> 16 & 0xff) / 255, green: Double(hex >> 8 & 0xff) / 255,
                blue: Double(hex & 0xff) / 255)
        }
    }
#endif
