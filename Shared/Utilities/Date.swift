import Foundation

extension Date {
    func autoFormatted() -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(self, equalTo: now, toGranularity: .hour) {
            return formatted(.relative(presentation: .named, unitsStyle: .wide))
        } else if calendar.isDate(self, inSameDayAs: now) {
            return formatted(date: .omitted, time: .shortened)
        } else {
            return formatted(date: .numeric, time: .omitted)
        }
    }
}
