import Foundation

extension Date {
    func autoFormatted() -> String {
        let now = Date.now
        let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
        
        if self > oneWeekAgo {
            return formatted(.relative(presentation: .named))
        } else {
            return formatted(date: .abbreviated, time: .omitted)
        }
    }
}
