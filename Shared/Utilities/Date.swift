import Foundation

extension Date {
    func autoFormatted() -> String {
        let now = Date.now
        let oneMonthAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        
        if self > oneMonthAgo {
            return formatted(.relative(presentation: .named))
        } else {
            return formatted(date: .abbreviated, time: .omitted)
        }
    }
}
