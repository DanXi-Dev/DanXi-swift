import Foundation

struct Semester: Identifiable, Hashable {
    var id: Int {
        year * 10 + semester
    }
    let year, semester: Int
    
    func formatted() -> LocalizedStringResource {
        switch semester {
        case 1:
            return LocalizedStringResource("\(String(year)) Fall Semester")
        case 2:
            return LocalizedStringResource("\(String(year)) Winter Vacation")
        case 3:
            return LocalizedStringResource("\(String(year)) Spring Semester")
        case 4:
            return LocalizedStringResource("\(String(year)) Summer Vacation")
        default:
            return LocalizedStringResource("\(String(year)) - \(semester)")
        }
    }
    
    static let empty = Semester(year: 0, semester: -1)
}
