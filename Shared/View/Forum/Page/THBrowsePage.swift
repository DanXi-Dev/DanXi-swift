import SwiftUI
import Utils

struct THBrowsePage: View {
    @ObservedObject private var settings = THSettings.shared
    @ObservedObject private var appModel = THModel.shared
    @EnvironmentObject private var model: THBrowseModel
    
    var body: some View {
        THBackgroundList {
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
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 8, trailing: 12))
                }
            }
            
            // Main Section
            AsyncCollection(model.filteredHoles, endReached: false,
                            action: model.loadMoreHoles)
            { hole in
                let fold = settings.sensitiveContent == .fold && hole.nsfw
                Section {
                    THHoleView(hole: hole, fold: fold)
                        .listRowInsets(EdgeInsets(top: (fold ? 6: 10), leading: 12, bottom: 8, trailing: 12))
                }
            }
            .id(model.configId) // stop old loading task when config change
        }
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
    @EnvironmentObject private var navigator: THNavigator
    
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
            Button {
                navigator.path.append(THPage.notifications)
            } label: {
                Label("Notifications", systemImage: "bell")
            }
            
            Button {
                navigator.path.append(THPage.favorite)
            } label: {
                Label("Favorites", systemImage: "star")
            }
            
            Button {
                navigator.path.append(THPage.subscription)
            } label: {
                Label("Subscription List", systemImage: "eye")
            }
            
            Button {
                navigator.path.append(THPage.mypost)
            } label: {
                Label("My Post", systemImage: "person")
            }
            
            Button {
                navigator.path.append(THPage.myreply)
            } label: {
                Label("My Reply", systemImage: "arrowshape.turn.up.left")
            }
            
            Button {
                navigator.path.append(THPage.history)
            } label: {
                Label("Recent Browsed", systemImage: "clock.arrow.circlepath")
            }
            
            Button {
                navigator.path.append(THPage.tags)
            } label: {
                Label("All Tags", systemImage: "tag")
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
                    
                    Button {
                        navigator.path.append(THPage.report)
                    } label: {
                        Label("Report", systemImage: "exclamationmark.triangle")
                    }
                    
                    Button {
                        navigator.path.append(THPage.moderate)
                    } label: {
                        Label("Moderate", systemImage: "video")
                    }
                    
                    NavigationLink("Send Message") {
                        THMessageSheet()
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
    @State private var collapse = false
    
    var body: some View {
        if collapse {
            EmptyView()
        } else {
            Section {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.circle.fill")
                    VStack(alignment: .leading) {
                        Text("You are banned in this division until \(date.formatted())")
                        Text("If you have any question, you may contact admin@fduhole.com")
                            .font(.footnote)
                    }
                    Spacer()
                    Button {
                        withAnimation {
                            collapse = true
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                .padding()
                .foregroundColor(.red)
                .background(.red.opacity(0.15))
                .cornerRadius(7)
                .listRowSeparator(.hidden)
            }
        }
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
            if currentBanner == banners.count {
                currentBanner = 0
            } else {
                currentBanner += 1
            }
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
                Form {
                    ScrollView {
                        ForEach(Array(banners.enumerated()), id: \.offset) { _, banner in
                            BannerView(banner: banner) {
                                showSheet = false // dismiss sheet when navigate to a hole page
                            }
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
    @EnvironmentObject private var navigator: THNavigator
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
            navigator.path.append(loader)
            navigationTapCallback()
        } else if let floorMatch = action.wholeMatch(of: /##(?<id>\d+)/),
                  let floorId = Int(floorMatch.id) {
            let loader = THHoleLoader(floorId: floorId)
            navigator.path.append(loader)
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
