import SwiftUI
import FudanKit
import ViewUtils
import Utils

public struct CampusHomePage: View {
    @ObservedObject private var model = CampusModel.shared
    @StateObject private var navigator = CampusNavigator()
    @State private var showSheet = false
    
    public init() {}
    
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
                .onReceive(OnDoubleTapCampusTabBarItem, perform: {
                    if navigator.path.count > 0 {
                        navigator.path.removeLast(navigator.path.count)
                    } else {
                        withAnimation {
                            proxy.scrollTo("campus-top")
                        }
                    }
                })
            }
            .toolbar {
                Button {
                    showSheet = true
                } label: {
                    Text("Edit")
                }
            }
//            .sheet(isPresented: $showSheet) {
//                HomePageEditor()
//            }
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
        case .course:
            EmptyView()
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
        case .course:
            EmptyView()
        }
    }
}
