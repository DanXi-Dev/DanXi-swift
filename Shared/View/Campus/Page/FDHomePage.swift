import SwiftUI

struct FDHomePage: View {
    @ObservedObject private var model = FDModel.shared
    @StateObject private var navigator = FDNavigator()
    
    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                ForEach(navigator.cards, id: \.self) { card in
                    FDHomeCard(section: card)
                        .swipeActions {
                            Button(role: .destructive) {
                                navigator.unpin(section: card)
                            } label: {
                                Image(systemName: "pin.slash.fill")
                            }
                        }
                }
                .onMove { from, to in
                    navigator.cards.move(fromOffsets: from, toOffset: to)
                }
                
                Section {
                    ForEach(navigator.pages, id: \.self) { section in
                        if (model.studentType == .undergrad) ||
                            (model.studentType == .grad && !FDSection.gradHidden.contains(section)) ||
                            (model.studentType == .staff && !FDSection.staffHidden.contains(section)) {
                            FDHomeSimpleLink(section: section)
                                .swipeActions {
                                    if FDSection.pinnable.contains(section) {
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
                    .onMove { from, to in
                        navigator.pages.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            .navigationTitle("Campus Services")
            .navigationDestination(for: FDSection.self) { section in
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
    let section: FDSection
    
    var body: some View {
        NavigationLink(value: section) {
            switch section {
            case .sport:
                Label("PE Curriculum", systemImage: "figure.disc.sports")
            case .pay:
                Label("Fudan QR Code", systemImage: "qrcode")
            case .bus:
                Label("Bus Schedule", systemImage: "bus.fill")
            case .ecard:
                Label("ECard Information", systemImage: "creditcard")
            case .score:
                Label("Exams & Score", systemImage: "graduationcap")
            case .rank:
                Label("GPA Rank", systemImage: "chart.bar.xaxis")
            case .playground:
                Label("Playground Reservation", systemImage: "sportscourt")
            case .courses:
                Label("Empty Classrooms", systemImage: "building.2")
            case .electricity:
                Label("Dorm Electricity", systemImage: "powercord.fill")
            case .notice:
                Label("Academic Office Announcements", systemImage: "bell")
            case .library:
                Label("Library Popularity", systemImage: "building.columns.fill")
            case .canteen:
                Label("Canteen Popularity", systemImage: "fork.knife")
            }
        }
    }
}

fileprivate struct FDHomeCard: View {
    @EnvironmentObject private var navigator: FDNavigator
    
    let section: FDSection
    
    var body: some View {
        Button {
            navigator.path.append(section)
        } label: {
            switch section {
            case .ecard:
                FDECardCard()
            case .electricity:
                FDElectricityCard()
            case .notice:
                FDNoticeCard()
            default:
                EmptyView()
            }
        }
        .tint(.primary)
        .frame(height: 85)
        .padding(13)
        .listRowBackground(EmptyView())
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .background {
            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                .foregroundStyle(Color.secondarySystemGroupedBackground)
        }
        .padding(.bottom, 8)
        
    }
}

fileprivate struct FDHomeDestination: View {
    let section: FDSection
    
    var body: some View {
        switch section {
        case .sport:
            FDSportPage()
        case .pay:
            FDPayPage()
        case .bus:
            FDBusPage()
        case .ecard:
            FDECardPage()
        case .score:
            FDScorePage()
        case .rank:
            FDRankPage()
        case .playground:
            FDPlaygroundPage()
        case .courses:
            FDClassroomPage()
        case .electricity:
            FDElectricityPage()
        case .notice:
            FDNoticePage()
        case .library:
            FDLibraryPage()
        case .canteen:
            FDCanteenPage()
        }
    }
}

#Preview {
    FDHomePage()
}
