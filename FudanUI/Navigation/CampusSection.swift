import SwiftUI

public enum CampusSection: String, Identifiable, Codable, CaseIterable {
    case wallet, electricity, announcenemnt, pay, bus, classroom, library, canteen, sport, score, rank, playground, exam
    case course
    
    public var id: CampusSection {
        self
    }
    
    static let allHidden: Set<CampusSection> = [.course]
    static let gradHidden: Set<CampusSection> = [.sport, .rank, .score, .exam]
    static let staffHidden: Set<CampusSection> = [.sport, .rank, .score, .electricity, .exam]
    static let pinnable: Set<CampusSection> = [.wallet, .electricity, .announcenemnt]
}

extension CampusSection {
    @ViewBuilder
    var label: some View {
        switch self {
        case .sport:
            Label("PE Curriculum", systemImage: "figure.disc.sports")
        case .pay:
            Label("Fudan QR Code", systemImage: "qrcode")
        case .bus:
            Label("Bus Schedule", systemImage: "bus.fill")
        case .exam:
            Label("Exams", systemImage: "book.pages")
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
            Label("Calendar", systemImage: "calendar")
        }
    }
    
    @ViewBuilder
    var card: some View {
        switch self {
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
    
    @ViewBuilder
    var destination: some View {
        switch self {
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
        case .exam:
            ExamPage()
        case .course:
            CoursePage()
        }
    }
}
