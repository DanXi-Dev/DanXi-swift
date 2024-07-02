import Foundation

struct Semester: Identifiable, Hashable {
    var id: Int {
        year * 10 + semester
    }
    let year, semester: Int
    
    func formatted() -> String {
        switch semester {
        case 1:
            return String(localized: "\(String(year))-\(String(year + 1)) Fall Semester", bundle: .module)
        case 2:
            return String(localized: "\(String(year))-\(String(year + 1)) Winter Vacation", bundle: .module)
        case 3:
            return String(localized: "\(String(year))-\(String(year + 1)) Spring Semester", bundle: .module)
        case 4:
            return String(localized: "\(String(year))-\(String(year + 1)) Summer Vacation", bundle: .module)
        default:
            return "\(String(year)) - \(semester)"
        }
    }
    
    static let empty = Semester(year: 0, semester: -1)
}
