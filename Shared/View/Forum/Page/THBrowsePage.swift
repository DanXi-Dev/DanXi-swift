import SwiftUI
import ViewUtils
import Utils

struct THBrowsePage: View {
    @ObservedObject private var settings = THSettings.shared
    @ObservedObject private var appModel = THModel.shared
    @EnvironmentObject private var model: THBrowseModel
    @EnvironmentObject private var mainAppModel: AppModel
    @State private var showScreenshotAlert = false
    
    private let screenshotPublisher = NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
    
    var body: some View {
        ScrollViewReader { proxy in
            THBackgroundList {
                EmptyView()
                    .id("th-top")
                
                THDivisionPicker()
                    .listRowInsets(EdgeInsets(.all, 0))
                    .listRowBackground(Color.clear)
                
                if settings.showBanners && !appModel.banners.isEmpty {
                    Section {
                        BannerCarousel(banners: appModel.banners)
                            .listRowInsets(EdgeInsets(.all, 0))
                    }
                }
                
                // Banned Notice
                if let bannedDate = model.bannedDate {
                    BannedNotice(date: bannedDate)
                }
                
                // Pinned Holes
                if !model.division.pinned.isEmpty {
                    ForEach(model.division.pinned) { hole in
                        Section {
                            THHoleView(hole: hole, pinned: true)
                        }
                    }
                }
                
                // Main Section
                AsyncCollection(model.filteredHoles, endReached: false,
                                action: model.loadMoreHoles) { hole in
                    let fold = settings.sensitiveContent == .fold && hole.nsfw
                    Section {
                        THHoleView(hole: hole, fold: fold)
                    }
                }
                .id(model.configId) // stop old loading task when config change
            }
            .listStyle(.insetGrouped)
            .onReceive(OnDoubleTapForumTabBarItem) {
                withAnimation {
                    proxy.scrollTo("th-top")
                }
            }
        }
        .watermark()
        .animation(.default, value: model.division)
        .navigationTitle(model.division.name)
        .refreshable {
            await model.refresh()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                THBrowseToolbar()
                    .environmentObject(model)
            }
        }
        .onReceive(ConfigurationCenter.bannerPublisher) { banner in
            appModel.banners = banner
        }
        .onReceive(screenshotPublisher) { _ in
            if settings.screenshotAlert && mainAppModel.screen == .forum {
                showScreenshotAlert = true
            }
        }
        .alert("Screenshot Detected", isPresented: $showScreenshotAlert) {} message: {
            Text("Screenshot Alert Content")
        }
        .onAppear {
            withAnimation {
                appModel.banners = ConfigurationCenter.configuration.banners
            }
        }
    }
}

private struct THDivisionPicker: View {
    @ObservedObject private var appModel = THModel.shared
    @EnvironmentObject private var model: THBrowseModel
    
    var body: some View {
        Picker("Division Selector", selection: $model.division) {
            ForEach(appModel.divisions) { division in
                Text(division.name)
                    .tag(division)
            }
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
    }
}

private struct THDatePicker: View {
    @EnvironmentObject private var model: THBrowseModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                let dateBinding = Binding<Date>(
                    get: { model.baseDate ?? Date() },
                    set: { model.baseDate = $0 }
                )
                
                DatePicker("Start Date", selection: dateBinding, in: ...Date.now, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                
                if model.baseDate != nil {
                    Button("Clear Date", role: .destructive) {
                        model.baseDate = nil
                        dismiss()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .navigationTitle("Select Date")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct THBrowseToolbar: View {
    @ObservedObject private var appModel = DXModel.shared
    @EnvironmentObject private var model: THBrowseModel
    
    @State private var showPostSheet = false
    @State private var showDatePicker = false
    @State private var showDivisionSheet = false
    @State private var showQuestionSheet = false
    
    var body: some View {
        HStack {
            postButton
            moreOptions
        }
        .sheet(isPresented: $showPostSheet) {
            THPostSheet(divisionId: model.division.id)
        }
        .sheet(isPresented: $showDatePicker) {
            THDatePicker()
                .environmentObject(model)
        }
        .sheet(isPresented: $showDivisionSheet) {
            THDivisionSheet(divisionId: model.division.id)
        }
        .sheet(isPresented: $showQuestionSheet) {
            DXQuestionSheet()
        }
    }
    
    private var postButton: some View {
        Button {
            if appModel.answered {
                showPostSheet = true
            } else {
                showQuestionSheet = true
            }
        } label: {
            Image(systemName: "square.and.pencil")
        }
    }
    
    private var moreOptions: some View {
        Menu {
            ForEach(ForumSection.userFeatures) { section in
                ContentLink(value: section) {
                    section.label
                }
            }
            
            Divider()
            
            Picker(selection: $model.sortOption) {
                Text("Last Updated")
                    .tag(THBrowseModel.SortOption.replyTime)
                Text("Last Created")
                    .tag(THBrowseModel.SortOption.createTime)
            } label: {
                Label("Sort By", systemImage: "arrow.up.arrow.down")
            }
            .pickerStyle(.menu)
            
            Button {
                showDatePicker = true
            } label: {
                Label("Select Date", systemImage: "clock.arrow.circlepath")
            }
            
            if appModel.isAdmin {
                Divider()
                
                Menu {
                    Button {
                        showDivisionSheet = true
                    } label: {
                        Label("Edit Division Info", systemImage: "rectangle.3.group")
                    }
                    
                    ForEach(ForumSection.adminFeatures) { section in
                        ContentLink(value: section) {
                            section.label
                        }
                    }
                } label: {
                    Label("Admin Actions", systemImage: "person.badge.key")
                }
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

private struct BannedNotice: View {
    let date: Date
    
    var body: some View {
        Section {
            HStack(alignment: .top) {
                Image(systemName: "exclamationmark.circle.fill")
                VStack(alignment: .leading) {
                    Text("You are banned in this division until \(date.formatted())")
                    Text("If you have any question, you may contact admin@fduhole.com")
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

private struct BannerCarousel: View {
    let banners: [Banner]
    @State private var showSheet = false
    @State private var currentBanner: Int = 0
    @ScaledMetric private var containerHeight: CGFloat = 70
    private let timer = Timer.publish(every: 5, on: .main, in: .default).autoconnect()
    
    private func updateBanner() {
        withAnimation {
            currentBanner += 1
            currentBanner %= banners.count
        }
    }
    
    var body: some View {
        TabView(selection: $currentBanner) {
            ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                BannerView(banner: banner)
                    .tag(index)
                    .onTapGesture {
                        showSheet = true
                    }
            }
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
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSheet = false
                        } label: {
                            Text("Done")
                        }
                    }
                }
                .navigationTitle("All Banners")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

private struct BannerView: View {
    let banner: Banner
    let navigationTapCallback: () -> Void
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var navigator: AppNavigator
    @ScaledMetric private var height: CGFloat = 20
    @ScaledMetric private var fontSize: CGFloat = 15
    
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
            let loader = THHoleLoader(holeId: holeId)
            navigator.pushDetail(value: loader, replace: true)
            navigationTapCallback()
        } else if let floorMatch = action.wholeMatch(of: /##(?<id>\d+)/),
                  let floorId = Int(floorMatch.id) {
            let loader = THHoleLoader(floorId: floorId)
            navigator.pushDetail(value: loader, replace: true)
            navigationTapCallback()
        } else if let url = URL(string: action) {
            openURL(url)
        }
    }
    
    var body: some View {
        HStack {
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
        .font(.system(size: fontSize))
        .frame(height: height)
        .padding()
    }
}
