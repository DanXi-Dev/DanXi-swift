import SwiftUI


/// Main page section, displaying hole contents and division switch bar
struct BrowsePage: View {
    @ObservedObject var preference = Preference.shared
    
    @EnvironmentObject var viewModel: BrowseViewModel
    
    @State var showDatePicker = false
    @State var showEditPage = false
    @State var showTagPage = false
    @State var showFavoritesPage = false
    @State var showReportPage = false
    
    var body: some View {        
        ScrollView {
            LazyVStack(alignment: .leading) {
                switchBar
                
                // MARK: Pinned Section
                if !viewModel.currentDivision.pinned.isEmpty {
                    Label("Pinned", systemImage: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                Divider()
                ForEach(viewModel.currentDivision.pinned) { hole in
                    HoleView(hole: hole)
                    Divider()
                }
                
                // MARK: Main Section
                HStack {
                    Label("Main Section", systemImage: "text.bubble.fill")
                    Spacer()
                    if let baseDate = viewModel.baseDate {
                        Text(baseDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .foregroundColor(.secondary)
                .font(.caption)
                .padding(.top)
                
                Divider()
                
                ForEach(viewModel.filteredHoles) { hole in
                    HoleView(hole: hole, fold: (hole.nsfw && preference.nsfwSetting == .fold))
                        .task {
                            if hole == viewModel.filteredHoles.last {
                                await viewModel.loadMoreHoles()
                            }
                        }
                    Divider()
                }
                
                if !viewModel.endReached {
                    LoadingFooter(loading: $viewModel.loading,
                                  errorDescription: viewModel.errorInfo,
                                  action: viewModel.loadMoreHoles)
                }
                
            }
            .padding(.horizontal)
        }
        .task {
            await viewModel.loadMoreHoles()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle(viewModel.currentDivision.name)
        .sheet(isPresented: $showDatePicker) {
            datePicker
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                menu
                
                Button(action: { showEditPage = true }) {
                    Image(systemName: "square.and.pencil")
                }
                .sheet(isPresented: $showEditPage) {
                    EditForm(divisionId: viewModel.currentDivision.id)
                }
            }
        }
    }
    
    private var switchBar: some View {
        Picker("division_selector", selection: $viewModel.currentDivision) {
            ForEach(TreeholeStore.shared.divisions) { division in
                Text(division.name)
                    .tag(division)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.currentDivision) { newValue in
            Task {
                await viewModel.refresh()
            }
        }
    }
    
    
    private var datePicker: some View {
        NavigationView {
            Form {
                DatePicker("Start Date",
                           selection: Binding<Date>(
                            get: { viewModel.baseDate ?? Date() },
                            set: { viewModel.baseDate = $0 }
                           ),
                           in: ...Date.now,
                           displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .onChange(of: viewModel.baseDate) { newValue in
                    Task {
                        showDatePicker = false
                        await viewModel.refresh()
                    }
                }
                
                if viewModel.baseDate != nil {
                    Button("Clear Date", role: .destructive) {
                        showDatePicker = false
                        Task {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var menu: some View {
        Menu {
            Button {
                showFavoritesPage = true
            } label: {
                Label("Favorites", systemImage: "star")
            }
            
            Button {
                showTagPage = true
            } label: {
                Label("Tags", systemImage: "tag")
            }
            
            Button {
                showDatePicker = true
            } label: {
                Label("Select Date", systemImage: "clock.arrow.circlepath")
            }
            
            Picker("Sort Options", selection: $viewModel.sortOption) {
                Text("Last Updated")
                    .tag(BrowseViewModel.SortOptions.byReplyTime)
                
                Text("Last Created")
                    .tag(BrowseViewModel.SortOptions.byCreateTime)
            }
            
            if UserStore.shared.isAdmin {
                Divider()
                
                Button {
                    showReportPage = true
                } label: {
                    Label("Reports Management", systemImage: "exclamationmark.triangle")
                }
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .background(
            Group {
                NavigationLink(destination: TagsPage(), isActive: $showTagPage) {
                    EmptyView()
                }
                NavigationLink(destination: FavoritesPage(), isActive: $showFavoritesPage) {
                    EmptyView()
                }
                NavigationLink(destination: ReportPage(), isActive: $showReportPage) {
                    EmptyView()
                }
            }
        )
    }
}
