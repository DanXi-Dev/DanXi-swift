import SwiftUI
import FudanKit
import ViewUtils
import Utils

public struct CampusHome: View {
    @EnvironmentObject private var tabViewModel: TabViewModel
    @EnvironmentObject private var navigator: AppNavigator
    @ObservedObject private var campusModel = CampusModel.shared
    @StateObject private var model = CampusHomeModel()
    @State private var showSheet = false
    #if os(watchOS)
    @State private var showLogoutAlert = false
    #endif
    
    private func shouldDisplay(section: CampusSection) -> Bool {
        switch campusModel.studentType {
        case .undergrad: true
        case .grad: !CampusSection.gradHidden.contains(section)
        case .staff: !CampusSection.staffHidden.contains(section)
        }
    }
    
    public init() {}
    
    public var body: some View {
        #if os(watchOS)
        List {
            ForEach(CampusSection.allCases) { section in
                let hiddenSet = switch campusModel.studentType {
                case .undergrad:
                    Set<CampusSection>() // empty set
                case .grad:
                    CampusSection.gradHidden
                case .staff:
                    CampusSection.staffHidden
                }
                
                if !hiddenSet.contains(section) {
                    DetailLink(value: section) {
                        section.label.navigationStyle()
                    }
                }
            }
            
            Button(role: .destructive) {
                showLogoutAlert = true
            } label: {
                Text("Logout", bundle: .module)
            }
        }
        .alert(String(localized: "Do you really want to logout?", bundle: .module), isPresented: $showLogoutAlert) {
            Button(role: .destructive) {
                showLogoutAlert = false
                campusModel.logout()
            } label: {
                Text("Logout", bundle: .module)
            }
            
            Button(role: .cancel) {
                showLogoutAlert = false
            } label: {
                Text("Cancel", bundle: .module)
            }
        }
        .navigationTitle(String(localized: "Campus Services", bundle: .module))
        #else
        ScrollViewReader { proxy in
            List {
                EmptyView()
                    .id("campus-top")
                
                if #available(iOS 16.1, *) {
                    ForEach(model.pinned) { section in
                        Section {
                            DetailLink(value: section) {
                                section.card
                                    .tint(.primary)
                                    .frame(height: 85)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    model.unpin(section: section)
                                } label: {
                                    Image(systemName: "pin.slash.fill")
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        ForEach(model.pinned) { section in
                            DetailLink(value: section) {
                                section.card
                                    .tint(.primary)
                                    .frame(height: 85)
                            }
                            .padding(13)
                            .listRowBackground(EmptyView())
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .background {
                                RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                                    .foregroundStyle(Color(uiColor: .secondarySystemGroupedBackground))
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
                
                Section {
                    // on wide screen, do not use dedicated section for calendar. instead, we'll use home page as entry.
                    if !navigator.isCompactMode {
                        DetailLink(value: CampusSection.course) {
                            CampusSection.course.label.navigationStyle()
                        }
                    }
                    
                    ForEach(model.unpinned) { section in
                        if shouldDisplay(section: section) {
                            DetailLink(value: section) {
                                section.label.navigationStyle()
                            }
                            .swipeActions {
                                if CampusSection.pinnable.contains(section) {
                                    Button {
                                        model.pin(section: section)
                                    } label: {
                                        Image(systemName: "pin.fill")
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .onReceive(tabViewModel.scrollControl) { _ in
                withAnimation {
                    proxy.scrollTo("campus-top")
                }
            }
        }
        .listStyle(.insetGrouped)
        .compactSectionSpacing()
        .navigationTitle(String(localized: "Campus Services", bundle: .module))
        .toolbar {
            Button {
                showSheet = true
            } label: {
                Text("Edit", bundle: .module)
            }
        }
        .sheet(isPresented: $showSheet) {
            HomePageEditor()
                .environmentObject(model)
        }
        #endif
    }
}

struct HomePageEditor: View {
    @EnvironmentObject private var model: CampusHomeModel
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var buttonSize = 23
    @State private var id = UUID()
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.pinned) { section in
                        section.label
                    }
                    .onMove { indices, newOffset in
                        model.pinned.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    .onDelete { indecies in
                        indecies.forEach { i in
                            withAnimation {
                                let removed = model.pinned.remove(at: i)
                                model.unpinned.append(removed)
                            }
                        }
                    }
                } header: {
                    Text("Pinned Features", bundle: .module)
                }
                
                Section {
                    ForEach(model.unpinned) { section in
                        HStack {
                            section.label
                            Spacer()
                            if CampusSection.pinnable.contains(section) {
                                Button {
                                    model.pin(section: section)
                                } label: {
                                    Image(systemName: "pin.circle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.system(size: buttonSize))
                                }
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        model.unpinned.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    .onDelete { indecies in
                        indecies.forEach { i in
                            withAnimation {
                                let removed = model.unpinned.remove(at: i)
                                model.hidden.append(removed)
                            }
                        }
                    }
                } header: {
                    Text("All Features", bundle: .module)
                }
                .id(id) // a display bug, the remove button won't show if I don't force it to redraw
                
                if !model.hidden.isEmpty {
                    Section {
                        ForEach(model.hidden) { section in
                            HStack {
                                Button {
                                    model.unhide(section: section)
                                    id = UUID()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.system(size: buttonSize))
                                }
                                section.label
                            }
                        }
                    } header: {
                        Text("Hidden Features", bundle: .module)
                    }
                }
            }
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Text("Done", bundle: .module)
                        .bold()
                }
            }
            #if !os(watchOS)
            .environment(\.editMode, .constant(.active))
            #endif
            .navigationTitle(String(localized: "Edit Home Page Features", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

@MainActor
class CampusHomeModel: ObservableObject {
    @AppStorage("campus-pinned") var pinned: [CampusSection] = []
    @AppStorage("campus-unpinned") var unpinned: [CampusSection] = []
    @AppStorage("campus-hidden") var hidden: [CampusSection] = []
    
    init() {
        for section in CampusSection.allCases {
            // course section is not user-configurable
            if section == .course {
                continue
            }
            
            if !pinned.contains(section), !unpinned.contains(section), !hidden.contains(section) {
                // a newly added feature through app update should be append to appropriate position
                if CampusSection.pinnable.contains(section) {
                    pinned.append(section)
                } else {
                    unpinned.append(section)
                }
            }
        }
    }
    
    func pin(section: CampusSection) {
        if unpinned.contains(section) && CampusSection.pinnable.contains(section) {
            withAnimation {
                unpinned.removeAll { $0 == section }
                pinned.append(section)
            }
        }
    }
    
    func unpin(section: CampusSection) {
        if pinned.contains(section) {
            withAnimation {
                pinned.removeAll { $0 == section }
                unpinned.append(section)
            }
        }
    }
    
    func hide(section: CampusSection) {
        if unpinned.contains(section) {
            withAnimation {
                unpinned.removeAll { $0 == section }
                hidden.append(section)
            }
        }
    }
    
    func unhide(section: CampusSection) {
        if hidden.contains(section) {
            withAnimation {
                hidden.removeAll { $0 == section }
                unpinned.append(section)
            }
        }
    }
}

#Preview {
    CampusHome()
        .previewPrepared()
        .environmentObject(AppNavigator())
}
