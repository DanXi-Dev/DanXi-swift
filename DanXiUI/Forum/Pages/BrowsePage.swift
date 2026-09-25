import SwiftUI
import TipKit
import Utils
import ViewUtils
import DanXiKit

struct BrowsePage: View {
    @EnvironmentObject private var tabViewModel: TabViewModel
    @EnvironmentObject private var model: BrowseModel
    @ObservedObject private var divisionStore = DivisionStore.shared
    @ObservedObject private var settings = ForumSettings.shared
    @ObservedObject private var profileStore = ProfileStore.shared
    
    @State private var showPostSheet = false
    @State private var draftPostSheet: Post?
    @State private var showDatePicker = false
    @State private var showDivisionSheet = false
    @State private var showQuestionSheet = false
    
    @available(iOS 17.0, *)
    private var changeVisibilityTip : ChangeVisibilityTip {.init()}

    // HoleView's own listRowInsets win over holeCard's, so the inter-card gap must be set here.
    // Tighter vertical insets on iOS 26 pull the plain-list cards close together; default look below iOS 26.
    private var homeHoleInsets: EdgeInsets {
        if #available(iOS 26.0, macOS 26.0, *) {
            return forumCardInsets
        } else {
            return EdgeInsets(top: 8, leading: 9, bottom: 8, trailing: 9)
        }
    }
    
    // Dragging a hole out of the iOS 26 home list is disabled (long-press still works); earlier systems keep it.
    private var homeHoleAllowsDrag: Bool {
        if #available(iOS 26.0, macOS 26.0, *) {
            false
        } else {
            true
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ForumList {
                EmptyView().id("forum-top")
                
                divisionPicker
                    .cardAlignedRow(bottom: 11, legacyInsets: EdgeInsets(.all, 0)) // keeps the cards clear of the picker

                forumSection {
                    BannerCarousel()
                        .bannerCard()
                }
                
                bannedNotice
                
                if #available(iOS 17.0, *){
                    TipView(changeVisibilityTip){
                        action in
                        if action.id == "go-to-settings"{
                            AppEvents.foldedContentSettings.send()
                        }
                    }
                    .tipBackground(.clear)
                    .cardAlignedRow()
                }
                
                if !model.division.pinned.isEmpty {
                    ForEach(model.division.pinned) { hole in
                        forumSection {
                            HoleView(presentation: HolePresentation(hole: hole), pinned: true, allowDrag: homeHoleAllowsDrag, rowInsets: homeHoleInsets)
                                .holeCard()
                        }
                    }
                }
                
                AsyncCollection(model.holes, endReached: model.endReached, action: model.loadMoreHoles) { hole in
                    let fold = settings.foldedContent == .fold && hole.sensitive
                    forumSection {
                        HoleView(presentation: hole, fold: fold, allowDrag: homeHoleAllowsDrag, rowInsets: homeHoleInsets)
                            .holeCard()
                    }
                }
                .id(model.configurationId) // stop old loading task when config change
            }
            .modifier(ForumCardListStyle()) // .plain + manual cards on iOS 26, .insetGrouped below
            .onReceive(tabViewModel.scrollControl) {
                withAnimation {
                    proxy.scrollTo("forum-top")
                }
            }
            .onChange(of: settings.blockedHoles) { blockedIds in
                withAnimation {
                    model.holes = model.holes.filter { !blockedIds.contains($0.id) }
                }
            }
        }
        .watermark()
        .animation(.default, value: model.division)
        .navigationTitle(model.division.name)
        .refreshable {
            try? await withHaptics(success: false) {
                try await model.refresh()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                toolbar
            }
        }
        .sheet(isPresented: $showPostSheet) {
            PostSheet(divisionId: model.division.id)
        }
        .sheet(item: $draftPostSheet) { post in
            PostSheet(divisionId: model.division.id, content: post.content, tags: post.tags)
        }
        .sheet(isPresented: $showDatePicker) {
            datePicker
        }
        .sheet(isPresented: $showDivisionSheet) {
            DivisionSheet(divisionId: model.division.id)
        }
        .sheet(isPresented: $showQuestionSheet) {
            QuestionSheet()
        }
        .screenshotAlert()
    }
    
    private var divisionPicker: some View {
        Picker(selection: $model.division) {
            ForEach(divisionStore.divisions) { division in
                Text(division.name)
                    .tag(division)
            }
        } label: {
            Text("Division Selector", bundle: .module)
        }
        .pickerStyle(.segmented)
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private var bannedNotice: some View {
        if let date = profileStore.profile?.bannedDivision[model.division.id] {
            forumSection {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.circle.fill")
                    VStack(alignment: .leading) {
                        Text("You are banned in this division until \(date.formatted())", bundle: .module)
                        Text("If you have any question, you may contact admin@fduhole.com", bundle: .module)
                            .font(.footnote)
                    }
                }
                .padding(.vertical, 8)
                .foregroundColor(.red)
                .bannedCard()
            }
            .environment(\.openURL, OpenURLAction { url in
                UIApplication.shared.open(url)
                return .handled
            })
        }
    }
    
    @ViewBuilder
    private var toolbar: some View {
        AsyncButton {
            if profileStore.answered {
                if let draftPost = await DraftboxStore.shared.getPost() {
                    draftPostSheet = draftPost
                } else {
                    showPostSheet = true
                }
            } else {
                showQuestionSheet = true
            }
        } label: {
            Image(systemName: "square.and.pencil")
        }
        
        Menu {
            ForEach(ForumSection.userFeatures) { section in
                ContentLink(value: section) {
                    section.label
                }
            }
            
            // "Admin Actions" is deliberately not the last element of this menu on iOS 26. There an
            // expanded submenu is drawn as a raised card that grows downward out of its own row and
            // overlays the siblings below it. When the submenu is last there is nothing below to
            // overlay, so UIKit slides the whole card upwards over the section above it instead —
            // measured at ~108pt here, which reads as the menu jumping. Keeping a section after it
            // leaves the card room to grow downwards and the row stays put. Earlier systems keep
            // the original order.
            if #available(iOS 26.0, macOS 26.0, *) {
                adminActions
                listOptions
            } else {
                listOptions
                adminActions
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    @ViewBuilder
    private var adminActions: some View {
        if profileStore.isAdmin {
            Divider()
            
            Menu {
                Button {
                    showDivisionSheet = true
                } label: {
                    Label(String(localized: "Edit Division Info", bundle: .module), systemImage: "rectangle.3.group")
                }
                
                ForEach(ForumSection.adminFeatures) { section in
                    ContentLink(value: section) {
                        section.label
                    }
                }
            } label: {
                Label(String(localized: "Admin Actions", bundle: .module), systemImage: "person.badge.key")
            }
        }
    }
    
    @ViewBuilder
    private var listOptions: some View {
        Divider()
        
        Picker(selection: $model.sortOption) {
            Text("Last Updated", bundle: .module)
                .tag(BrowseModel.SortOption.replyTime)
            Text("Last Created", bundle: .module)
                .tag(BrowseModel.SortOption.createTime)
        } label: {
            Label(String(localized: "Sort By", bundle: .module), systemImage: "arrow.up.arrow.down")
        }
        .pickerStyle(.menu)
        
        Button {
            showDatePicker = true
        } label: {
            Label(String(localized: "Select Date", bundle: .module), systemImage: "clock.arrow.circlepath")
        }
    }
    
    private var datePicker: some View {
        NavigationStack {
            Form {
                let dateBinding = Binding<Date>(
                    get: { model.baseDate ?? Date() },
                    set: { model.baseDate = $0 }
                )
                
                DatePicker(selection: dateBinding, in: ...Date.now, displayedComponents: [.date]) {
                    Text("Start Date", bundle: .module)
                }
                .datePickerStyle(.graphical)
                
                if model.baseDate != nil {
                    Button(role: .destructive) {
                        model.baseDate = nil
                        showDatePicker = false
                    } label: {
                        Text("Clear Date", bundle: .module)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDatePicker = false
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Select Date", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BannerCarousel: View {
    let banners = ConfigurationCenter.configuration.banners
    @State private var showSheet = false
    @State private var currentBanner: Int = 0
    @ScaledMetric private var containerHeight: CGFloat = 54
    @State private var timer = Timer.publish(every: 5, on: .main, in: .default).autoconnect()
    @ObservedObject private var settings = ForumSettings.shared
    
    // On iOS 26 the banner is a forum card, so its content lines up with the holes' content.
    private var horizontalPadding: CGFloat? {
        if #available(iOS 26.0, macOS 26.0, *) {
            forumCardContentPadding
        } else {
            nil
        }
    }
    
    private func updateBanner() {
        withAnimation {
            currentBanner += 1
            currentBanner %= banners.count
        }
    }
    
    var body: some View {
        if !banners.isEmpty && settings.showBanners {
            TabView(selection: $currentBanner) {
                ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                    BannerView(banner: banner, horizontalPadding: horizontalPadding)
                        .tag(index)
                        .onTapGesture {
                            showSheet = true
                        }
                }
            }
            .onChange(of: currentBanner) { _ in
                // reset timer after swipe
                timer.upstream.connect().cancel()
                timer = Timer.publish(every: 5, on: .main, in: .default).autoconnect()
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: containerHeight)
            .lineLimit(nil)
            .onReceive(timer) { _ in
                updateBanner()
            }
            .sheet(isPresented: $showSheet) {
                NavigationStack {
                    List {
                        ForEach(Array(banners.enumerated()), id: \.offset) { _, banner in
                            BannerView(banner: banner) {
                                showSheet = false // dismiss sheet when navigate to a hole page
                            }
                            .listRowInsets(.init(top: 0, leading: 2, bottom: 0, trailing: 2))
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showSheet = false
                            } label: {
                                Text("Done", bundle: .module)
                            }
                        }
                    }
                    .navigationTitle(String(localized: "All Banners", bundle: .module))
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct BannerView: View {
    let banner: Banner
    let horizontalPadding: CGFloat? // nil: default padding
    let navigationTapCallback: () -> Void
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var navigator: AppNavigator
    @ScaledMetric private var height: CGFloat = 20
    
    init(banner: Banner, horizontalPadding: CGFloat? = nil, navigationTapCallback: (() -> Void)? = nil) {
        self.banner = banner
        self.horizontalPadding = horizontalPadding
        if let callback = navigationTapCallback {
            self.navigationTapCallback = callback
        } else {
            self.navigationTapCallback = {} // empty closure
        }
    }
    
    private func actionButton(_ action: String) {
        if let holeMatch = action.wholeMatch(of: /#(?<id>\d+)/),
           let holeId = Int(holeMatch.id) {
            let loader = HoleLoader(holeId: holeId)
            navigator.pushDetail(value: loader, replace: true)
            navigationTapCallback()
        } else if let floorMatch = action.wholeMatch(of: /##(?<id>\d+)/),
                  let floorId = Int(floorMatch.id) {
            let loader = HoleLoader(floorId: floorId)
            navigator.pushDetail(value: loader, replace: true)
            navigationTapCallback()
        } else if let url = URL(string: action) {
            openURL(url)
        }
    }
    
    var body: some View {
        if let horizontalPadding {
            content
                .padding(.vertical)
                .padding(.horizontal, horizontalPadding)
        } else {
            content
                .padding()
        }
    }
    
    private var content: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "bell.fill")
                .foregroundColor(.accentColor)
            Text(banner.title)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            Spacer()
            Button(banner.button) {
                actionButton(banner.action)
            }
        }
        .font(.subheadline)
        .frame(height: height)
    }
}

#Preview {
    let holes: [Hole] = decodePreviewData(filename: "holes", directory: "forum")
    let presentations = holes.map { HolePresentation(hole: $0) }
    let divisions: [Division] = decodePreviewData(filename: "divisions", directory: "forum")
    let model = BrowseModel(division: divisions[0])
    model.holes = presentations
    model.endReached = true
    
    let navigator = AppNavigator()
    let tabViewModel = TabViewModel()
    
    return BrowsePage()
        .environmentObject(model)
        .environmentObject(navigator)
        .environmentObject(tabViewModel)
        .previewPrepared()
}

// MARK: - Forum home card styling (iOS 26 / macOS 26 only)
//
// On iOS 26 the system .insetGrouped / Liquid Glass cell corner radius became much larger than
// FloorView's hand-drawn 10pt card, and it crowds the row content. There is no public API to shrink
// a system grouped cell's corner, so on iOS 26 we switch the home list to .plain and draw every card
// (banner, banned notice, holes) ourselves, matching FloorView exactly. The app is Mac Catalyst, so the
// iOS 26 check already maps to macOS 26 (Tahoe); macOS 26.0 is named explicitly for clarity. Earlier
// iOS/macOS keep the original .insetGrouped look untouched.
//
// Row insets: the innermost listRowInsets wins, so a row's insets must be set by the modifiers below and
// not by the row itself.

private struct ForumCardListStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color("List Background", bundle: .module))
        } else {
            content
                .listStyle(.insetGrouped)
        }
    }
}

// On iOS 26 the home list is .plain, where each row's own Section adds a large, uncontrollable gap
// (plain ignores .listSectionSpacing). So on iOS 26 each card is a bare row — tight, uniform spacing
// driven only by listRowInsets. Below iOS 26 we keep the Section so the grouped style still renders
// each as its own card.
@ViewBuilder
private func forumSection<V: View>(@ViewBuilder _ content: () -> V) -> some View {
    if #available(iOS 26.0, macOS 26.0, *) {
        content()
    } else {
        Section { content() }
    }
}

/// Insets of every card row on iOS 26: 9pt side margins, and 3pt + 3pt = 6pt between adjacent cards.
@available(iOS 26.0, macOS 26.0, *)
private let forumCardInsets = EdgeInsets(top: 3, leading: 9, bottom: 3, trailing: 9)

/// Leading/trailing padding between a card's edge and its content, shared by all cards.
private let forumCardContentPadding: CGFloat = 12

private extension View {
    /// Draws a 10pt card as a direct `.background` of the content, so the card shares the content's
    /// geometry and cannot visually detach from it while scrolling.
    @available(iOS 26.0, macOS 26.0, *)
    func forumCard(_ fill: some ShapeStyle) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .foregroundStyle(fill)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
    
    /// A hole row's card. Its insets come from `HoleView(rowInsets:)`, since HoleView sets its own.
    /// iOS 26 only; passthrough below.
    @ViewBuilder
    func holeCard() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .padding(EdgeInsets(top: 8, leading: forumCardContentPadding, bottom: 8, trailing: forumCardContentPadding))
                .forumCard(Color("List Foreground", bundle: .module))
        } else {
            self
        }
    }

    /// The top banner as one more card of the list on iOS 26, where it stops being a grouped cell once the
    /// list switches to .plain. Below iOS 26 it is still a real grouped cell, so only zero insets are applied.
    @ViewBuilder
    func bannerCard() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .forumCard(Color("List Foreground", bundle: .module))
                .listRowInsets(forumCardInsets)
        } else {
            self
                .listRowInsets(EdgeInsets(.all, 0))
        }
    }
    
    /// The banned notice as a red-tinted card on iOS 26; below iOS 26 it keeps its red grouped cell.
    @ViewBuilder
    func bannedCard() -> some View {
        let tint = Color.red.opacity(0.15)
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .padding(.horizontal, forumCardContentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .forumCard(tint)
                .listRowInsets(forumCardInsets)
        } else {
            self
                .listRowBackground(tint)
        }
    }

    /// Styles a non-card row (picker, tip) for the iOS 26 plain list: hides the plain-style separator and
    /// re-insets horizontally by 16pt to replace the grouped section margin that .plain drops, lining up with
    /// the search bar. `bottom` lets the row above the cards keep them apart from it. Below iOS 26
    /// `legacyInsets`, if any, is applied instead.
    @ViewBuilder
    func cardAlignedRow(bottom: CGFloat = 2, legacyInsets: EdgeInsets? = nil) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: bottom, trailing: 16))
                .listRowSeparator(.hidden)
        } else if let legacyInsets {
            self
                .listRowInsets(legacyInsets)
        } else {
            self
        }
    }
}
