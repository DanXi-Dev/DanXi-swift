import SwiftUI
import SwiftUIX


/// Main page section, displaying hole contents and division switch bar
struct THBrowsePage: View {
    @ObservedObject var preference = Preference.shared
    @OptionalEnvironmentObject var router: NavigationRouter?
    @EnvironmentObject var viewModel: THBrowseModel
    
    @State var showDatePicker = false
    @State var showEditPage = false
    @State var showTagPage = false
    @State var showFavoritesPage = false
    @State var showReportPage = false
    
    var body: some View {
        List {
            switchBar
                .listRowSeparator(.hidden)
            
            // MARK: Pinned Section
            if !viewModel.currentDivision.pinned.isEmpty {
                Section {
                    ForEach(viewModel.currentDivision.pinned) { hole in
                        THBrowseRow(hole: hole)
                    }
                } header: {
                    Label("Pinned", systemImage: "pin.fill")
                }
            }
            
            // MARK: Main Section
            Section {
                ForEach(viewModel.filteredHoles) { hole in
                    THBrowseRow(hole: hole)
                        .task {
                            if hole == viewModel.filteredHoles.last {
                                await viewModel.loadMoreHoles()
                            }
                        }
                }
                
                if !viewModel.endReached {
                    LoadingFooter(loading: $viewModel.loading,
                                  errorDescription: viewModel.errorInfo,
                                  action: viewModel.loadMoreHoles)
                    .listRowSeparator(.hidden)
                }
            } header: {
                HStack {
                    Label("Main Section", systemImage: "text.bubble.fill")
                    Spacer()
                    if let baseDate = viewModel.baseDate {
                        Text(baseDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(viewModel.currentDivision.name)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadMoreHoles()
        }
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
                    THPostSheet(divisionId: viewModel.currentDivision.id)
                }
            }
        }
    }
    
    private var switchBar: some View {
        Picker("division_selector", selection: $viewModel.currentDivision) {
            ForEach(DXModel.shared.divisions) { division in
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
                router?.path.append(TreeholeStaticPages.favorites)
            } label: {
                Label("Favorites", systemImage: "star")
            }
            
            Button {
                showDatePicker = true
            } label: {
                Label("Select Date", systemImage: "clock.arrow.circlepath")
            }
            
            Picker("Sort Options", selection: $viewModel.sortOption) {
                Text("Last Updated")
                    .tag(THBrowseModel.SortOptions.byReplyTime)
                
                Text("Last Created")
                    .tag(THBrowseModel.SortOptions.byCreateTime)
            }
            
            if DXModel.shared.isAdmin {
                Divider()
                
                Button {
                    router?.path.append(TreeholeStaticPages.reports)
                } label: {
                    Label("Reports Management", systemImage: "exclamationmark.triangle")
                }
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

struct THBrowseRow: View {
    @ObservedObject var preference = Preference.shared
    let hole: THHole
    
    var body: some View {
        ListSeparatorWrapper {
            THHoleView(hole: hole,
                       fold: (hole.nsfw && preference.nsfwSetting == .fold))
                .padding(.top)
        }
    }
}
