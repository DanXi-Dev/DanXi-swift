import Foundation

struct Semester: Identifiable, Hashable {
    var id: Int {
        year * 10 + semester
    }
    let year, semester: Int
    
    func formatted() -> String {
        switch semester {
        case 1:
            return String(localized: "\(String(year)) Fall Semester", bundle: .module)
        case 2:
            return String(localized: "\(String(year)) Winter Vacation", bundle: .module)
        case 3:
            return String(localized: "\(String(year)) Spring Semester", bundle: .module)
        case 4:
            return String(localized: "\(String(year)) Summer Vacation", bundle: .module)
        default:
            return "\(String(year)) - \(semester)"
        }
    }
    
    static let empty = Semester(year: 0, semester: -1)
}
