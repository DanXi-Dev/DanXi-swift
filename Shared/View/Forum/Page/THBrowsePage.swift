import SwiftUI

struct THBrowsePage: View {
    @ObservedObject var settings = THSettings.shared
    @EnvironmentObject var model: THBrowseModel
    
    var body: some View {
        List {
            THDivisionPicker()
            
            // Pinned Holes
            if !model.division.pinned.isEmpty {
                Section {
                    Label("Pinned", systemImage: "pin.fill")
                        .bold()
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                        
                    
                    ForEach(model.division.pinned) { hole in
                        THHoleView(hole: hole)
                    }
                }
            }
            
            // Main Section
            Section {
                if !model.division.pinned.isEmpty { // only show lable when there is pinned section
                    Label("Main Section", systemImage: "text.bubble.fill")
                        .bold()
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                }
                
                ForEach(model.filteredHoles) { hole in
                    let fold = settings.sensitiveContent == .fold && hole.nsfw
                    THHoleView(hole: hole, fold: fold)
                        .task {
                            if hole == model.filteredHoles.last {
                                await model.loadMoreHoles()
                            }
                        }
                }
                
                LoadingFooter(loading: $model.loading,
                              errorDescription: model.loadingError?.localizedDescription ?? "") {
                    await model.loadMoreHoles()
                }
            }
            .task {
                await model.loadMoreHoles()
            }
        }
        .listStyle(.inset)
        .navigationTitle(model.division.name)
        .refreshable {
            await model.refresh()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                THBrowseToolbar()
            }
        }
    }
}

fileprivate struct THDivisionPicker: View {
    @EnvironmentObject var model: THBrowseModel
    
    var body: some View {
        Picker("Division Selector", selection: $model.division) {
            ForEach(DXModel.shared.divisions) { division in
                Text(division.name)
                    .tag(division)
            }
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
    }
}

fileprivate struct THDatePicker: View {
    @EnvironmentObject var model: THBrowseModel
    @Environment(\.dismiss) var dismiss
    
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
        }
        .navigationTitle("Select Date")
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct THBrowseToolbar: View {
    @EnvironmentObject var model: THBrowseModel
    
    @State var showPostSheet = false
    @State var showDatePicker = false
    
    var body: some View {
        Group {
            postButton
            filterMenu
        }
        .sheet(isPresented: $showPostSheet) {
            THPostSheet(divisionId: model.division.id)
        }
        .sheet(isPresented: $showDatePicker) {
            THDatePicker()
        }
    }
    
    private var postButton: some View {
        Button {
            showPostSheet = true
        } label: {
            Image(systemName: "square.and.pencil")
        }
    }
    
    private var filterMenu: some View {
        Menu {
            Picker("Sort Options", selection: $model.sortOption) {
                Text("Last Updated")
                    .tag(THBrowseModel.SortOption.replyTime)
                Text("Last Created")
                    .tag(THBrowseModel.SortOption.createTime)
            }
            
            Button {
                showDatePicker = true
            } label: {
                Label("Select Date", systemImage: "clock.arrow.circlepath")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
