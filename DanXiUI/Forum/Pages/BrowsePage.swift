import SwiftUI
import Utils
import ViewUtils
import DanXiKit

struct BrowsePage: View {
    @EnvironmentObject private var model: BrowseModel
    @ObservedObject private var divisionStore = DivisionStore.shared
    @ObservedObject private var settings = ForumSettings.shared
    @ObservedObject private var profileStore = ProfileStore.shared
    
    @State private var showPostSheet = false
    @State private var showDatePicker = false
    @State private var showDivisionSheet = false
    @State private var showQuestionSheet = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ForumList {
                EmptyView().id("forum-top")
                
                divisionPicker
                
                Section {
                    BannerCarousel()
                        .listRowInsets(EdgeInsets(.all, 0))
                }
                
                bannedNotice
                
                if !model.division.pinned.isEmpty {
                    ForEach(model.division.pinned) { hole in
                        Section {
                            HoleView(presentation: HolePresentation(hole: hole), pinned: true)
                        }
                    }
                }
                
                AsyncCollection(model.holes, endReached: model.endReached, action: model.loadMoreHoles) { hole in
                    let fold = settings.foldedContent == .fold && hole.sensitive
                    Section {
                        HoleView(presentation: hole, fold: fold)
                    }
                }
                .id(model.configurationId) // stop old loading task when config change
            }
            .listStyle(.insetGrouped)
            .onReceive(AppEvents.ScrollToTop.forum) {
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
        .listRowInsets(EdgeInsets(.all, 0))
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private var bannedNotice: some View {
        if let date = profileStore.profile?.bannedDivision[model.division.id] {
            Section {
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
                .listRowBackground(Color.red.opacity(0.15))
            }
            .environment(\.openURL, OpenURLAction { url in
                UIApplication.shared.open(url)
                return .handled
            })
        }
    }
    
    @ViewBuilder
    private var toolbar: some View {
        Button {
            if profileStore.answered {
                showPostSheet = true
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
        } label: {
            Image(systemName: "ellipsis.circle")
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
    
    private func updateBanner() {
        withAnimation {
            currentBanner += 1
            currentBanner %= banners.count
        }
    }
    
    var body: some View {
        if !banners.isEmpty {
            TabView(selection: $currentBanner) {
                ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                    BannerView(banner: banner)
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
    let navigationTapCallback: () -> Void
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var navigator: AppNavigator
    @ScaledMetric private var height: CGFloat = 20
    
    init(banner: Banner, navigationTapCallback: (() -> Void)? = nil) {
        self.banner = banner
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
        .padding()
    }
}

#Preview {
    let holes: [Hole] = decodePreviewData(filename: "holes", directory: "forum")
    let presentations = holes.map { HolePresentation(hole: $0) }
    let divisions: [Division] = decodePreviewData(filename: "divisions", directory: "forum")
    let model = BrowseModel(division: divisions[0])
    model.holes = presentations
    model.endReached = true
    
    return BrowsePage()
        .environmentObject(model)
        .previewPrepared()
}
