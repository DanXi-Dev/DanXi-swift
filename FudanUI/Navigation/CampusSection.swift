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
    static let pinnable: Set<CampusSection> = [.wallet, .electricity, .announcenemnt, .bus]
}

extension CampusSection {
    @ViewBuilder
    var label: some View {
        switch self {
        case .sport:
            Label(String(localized: "PE Curriculum", bundle: .module), systemImage: "figure.disc.sports")
        case .pay:
            Label(String(localized: "Fudan QR Code", bundle: .module), systemImage: "qrcode")
        case .bus:
            Label(String(localized: "Bus Schedule", bundle: .module), systemImage: "bus.fill")
        case .exam:
            Label(String(localized: "Exams", bundle: .module), systemImage: "book.closed")
        case .wallet:
            Label(String(localized: "ECard Information", bundle: .module), systemImage: "creditcard")
        case .score:
            Label(String(localized: "Exams & Score", bundle: .module), systemImage: "graduationcap.circle")
        case .rank:
            Label(String(localized: "GPA Rank", bundle: .module), systemImage: "chart.bar.xaxis")
        case .playground:
            Label(String(localized: "Playground Reservation", bundle: .module), systemImage: "sportscourt")
        case .classroom:
            Label(String(localized: "Classroom Schedule", bundle: .module), systemImage: "building.2")
        case .electricity:
            Label(String(localized: "Dorm Electricity", bundle: .module), systemImage: "bolt.fill")
        case .announcenemnt:
            Label(String(localized: "Academic Office Announcements", bundle: .module), systemImage: "bell")
        case .library:
            Label(String(localized: "Library Popularity", bundle: .module), systemImage: "building.columns.fill")
        case .canteen:
            Label(String(localized: "Canteen Popularity", bundle: .module), systemImage: "fork.knife")
        case .course:
            Label(String(localized: "Calendar", bundle: .module), systemImage: "calendar")
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
        case .bus:
            BusCard()
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
