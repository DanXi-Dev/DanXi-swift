import SwiftUI

struct FDHomePage: View {
    @StateObject var model = FDHomeModel()
    
    var body: some View {
        NavigationStack(path: $model.path) {
            List {
                ForEach(model.pages, id: \.self) { section in
                    FDHomeSimpleLink(section: section)
                }
                .onMove { from, to in
                    model.pages.move(fromOffsets: from, toOffset: to)
                }
            }
            .navigationTitle("Campus Services")
            .navigationDestination(for: FDSection.self) { section in
                FDHomeDestination(section: section)
            }
            .onOpenURL { url in
                model.openURL(url)
            }
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
                Label("Online Course Table", systemImage: "calendar")
            case .electricity:
                Label("Dorm Electricity", systemImage: "bolt.horizontal")
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
            FDCoursePage()
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
