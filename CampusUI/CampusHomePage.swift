import SwiftUI
import FudanKit
import ViewUtils

public struct CampusHomePage: View {
    @ObservedObject private var model = CampusModel.shared
    @StateObject private var navigator = CampusNavigator()
    @State private var showSheet = false
    
    public var body: some View {
        NavigationStack(path: $navigator.path) {
            ScrollViewReader { proxy in
                List {
                    EmptyView()
                        .id("campus-top")
                    
                    ForEach(navigator.cards, id: \.self) { card in
                        Section {
                            FDHomeCard(section: card)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        navigator.unpin(section: card)
                                    } label: {
                                        Image(systemName: "pin.slash.fill")
                                    }
                                }
                        }
                    }
                    
                    Section {
                        ForEach(navigator.pages, id: \.self) { section in
                            if (model.studentType == .undergrad) ||
                                (model.studentType == .grad && !CampusSection.gradHidden.contains(section)) ||
                                (model.studentType == .staff && !CampusSection.staffHidden.contains(section)) {
                                NavigationLink(value: section) {
                                    FDHomeSimpleLink(section: section)
                                }
                                .swipeActions {
                                    if CampusSection.pinnable.contains(section) {
                                        Button {
                                            navigator.pin(section: section)
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
                .compactSectionSpacing()
//                .onReceive(AppModel.onDoubleTapTabItem, perform: { (section: AppSection) in
//                    guard section == .settings else { return }
//                    if navigator.path.count > 0 {
//                        navigator.path.removeLast(navigator.path.count)
//                    } else {
//                        withAnimation {
//                            proxy.scrollTo("campus-top")
//                        }
//                    }
//                })
            }
            .toolbar {
                Button {
                    showSheet = true
                } label: {
                    Text("Edit")
                }
            }
            .sheet(isPresented: $showSheet) {
                HomePageEditor()
            }
            .navigationTitle("Campus Services")
            .navigationDestination(for: CampusSection.self) { section in
                FDHomeDestination(section: section)
            }
            .onOpenURL { url in
                navigator.openURL(url)
            }
            .environmentObject(navigator)
        }
    }
}

fileprivate struct HomePageEditor: View {
    @EnvironmentObject private var navigator: CampusNavigator
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var buttonSize = 23
    @State private var id = UUID()
    
    var body: some View {
        NavigationStack {
            List {
                Section("Pinned Features") {
                    ForEach(navigator.cards, id: \.self) { section in
                        FDHomeSimpleLink(section: section)
                    }
                    .onMove { indices, newOffset in
                        navigator.cards.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    .onDelete { indecies in
                        indecies.forEach { i in
                            withAnimation {
                                let removed = navigator.cards.remove(at: i)
                                navigator.pages.append(removed)
                            }
                        }
                    }
                }
                
                Section("All Features") {
                    ForEach(navigator.pages, id: \.self) { section in
                        HStack {
                            FDHomeSimpleLink(section: section)
                            Spacer()
                            if CampusSection.pinnable.contains(section) {
                                Button {
                                    navigator.pin(section: section)
                                } label: {
                                    Image(systemName: "pin.circle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.system(size: buttonSize))
                                }
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        navigator.pages.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    .onDelete { indecies in
                        indecies.forEach { i in
                            withAnimation {
                                let removed = navigator.pages.remove(at: i)
                                navigator.hidden.append(removed)
                            }
                        }
                    }
                }
                .id(id) // a display bug, the remove button won't show if I don't force it to redraw
                
                Section("Hidden Features") {
                    ForEach(navigator.hidden, id: \.self) { section in
                        HStack {
                            Button {
                                navigator.unhide(section: section)
                                id = UUID()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: buttonSize))
                            }
                            FDHomeSimpleLink(section: section)
                        }
                    }
                }
            }
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .bold()
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Edit Home Page Features")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

fileprivate struct FDHomeSimpleLink: View {
    let section: CampusSection
    
    var body: some View {
        switch section {
        case .sport:
            Label("PE Curriculum", systemImage: "figure.disc.sports")
        case .pay:
            Label("Fudan QR Code", systemImage: "qrcode")
        case .bus:
            Label("Bus Schedule", systemImage: "bus.fill")
        case .wallet:
            Label("ECard Information", systemImage: "creditcard")
        case .score:
            Label("Exams & Score", systemImage: "graduationcap.circle")
        case .rank:
            Label("GPA Rank", systemImage: "chart.bar.xaxis")
        case .playground:
            Label("Playground Reservation", systemImage: "sportscourt")
        case .classroom:
            Label("Classroom Schedule", systemImage: "building.2")
        case .electricity:
            Label("Dorm Electricity", systemImage: "bolt.fill")
        case .announcenemnt:
            Label("Academic Office Announcements", systemImage: "bell")
        case .library:
            Label("Library Popularity", systemImage: "building.columns.fill")
        case .canteen:
            Label("Canteen Popularity", systemImage: "fork.knife")
        }
    }
}

fileprivate struct FDHomeCard: View {
    @EnvironmentObject private var navigator: CampusNavigator
    
    let section: CampusSection
    
    var body: some View {
        Button {
            navigator.path.append(section)
        } label: {
            switch section {
            case .wallet:
                WalletCard()
            case .electricity:
                ElectricityCard()
            case .announcenemnt:
                AnnouncementCard()
            default:
                EmptyView()
            }
        }
        .tint(.primary)
        .frame(height: 85)
    }
}

fileprivate struct FDHomeDestination: View {
    let section: CampusSection
    
    var body: some View {
        switch section {
        case .sport:
            SportPage()
        case .pay:
            PayPage()
        case .bus:
            BusPage()
        case .wallet:
            WalletPage()
        case .score:
            ScorePage()
        case .rank:
            RankPage()
        case .playground:
            ReservationPage()
        case .classroom:
            ClassroomPage()
        case .electricity:
            ElectricityPage()
        case .announcenemnt:
            AnnouncementPage()
        case .library:
            LibraryPage()
        case .canteen:
            CanteenPage()
        }
    }
}
