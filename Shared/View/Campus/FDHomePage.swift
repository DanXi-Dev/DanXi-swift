import SwiftUI

struct FDHomePage: View {
    @StateObject var model = FDHomeModel()
    
    var body: some View {
        NavigationStack(path: $model.path) {
            List {
                ForEach(model.unpinned, id: \.self) { section in
                    FDHomeSimpleLink(section: section)
                }
                .onMove { from, to in
                    model.unpinned.move(fromOffsets: from, toOffset: to)
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
        }
    }
}

struct FDHomePage_Previews: PreviewProvider {
    static var previews: some View {
        FDHomePage()
    }
}
