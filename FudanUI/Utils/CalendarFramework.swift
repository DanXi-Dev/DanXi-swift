import SwiftUI
import FudanKit
import ViewUtils

// MARK: Courses

struct CourseView: View {
    @Environment(\.courseTint) private var courseTint
    let title: String
    let subtitle: String
    let span: Int
    
    @ScaledMetric private var titleSize = 15
    @ScaledMetric private var subtitleSize = 10
    
    private var color: Color {
        if let courseTint {
            courseTint
        } else {
            randomColor(title)
        }
    }
    
    var body: some View {
        CalDimensionReader { dim in
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .bold()
                        .padding(.top, 5)
                        .padding(.bottom, 1)
                        .foregroundColor(color)
                        .font(.system(size: titleSize))
                    Text(subtitle)
                        .foregroundColor(color)
                        .font(.system(size: subtitleSize))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                Spacer()
            }
            .padding(.leading, 8)
            .frame(width: dim.dx,
                   height: CGFloat(span) * dim.dy)
            .background(color.opacity(0.2))
            .overlay(Rectangle()
                .frame(width: 3)
                .foregroundColor(color), alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

// MARK: Backgrounds

struct DateHeader: View {
    let dateProvided: Bool
    let start: Date
    @Environment(\.calendar) private var calendar
    @ScaledMetric private var dateFont = 15
    @ScaledMetric private var weekFont = 10
    
    init(_ start: Date? = nil) {
        dateProvided = start != nil
        if let start = start {
            self.start = start
        } else {
            let calendar = Calendar.current
            let today = Date.now
            let daysSinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.day! -= daysSinceMonday
            self.start = calendar.date(from: dateComponents)!
        }
    }
    
    var body: some View {
        CalDimensionReader { dim in
            ZStack {
                ForEach(0 ..< 7) { i in
                    let point = CGPoint(x: dim.dx / 2 + CGFloat(i) * dim.dx, y: dim.y / 2)
                    let date = calendar.date(byAdding: .day, value: i, to: start)!
                    let isToday = calendar.isDateInToday(date)
                    VStack(alignment: .center, spacing: 5) {
                        if dateProvided {
                            Text(date.formatted(.dateTime.month(.defaultDigits).day()))
                                .foregroundColor(isToday ? .accentColor : .primary)
                                .font(.system(size: dateFont))
                        }
                        Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: weekFont))
                    }
                    .fontWeight(isToday ? .bold : .regular)
                    .position(point)
                }
            }
            .frame(height: dim.y)
        }
    }
}

struct TimeslotsSidebar: View {
    private let h = ClassTimeSlot.list.count
    private let formatter: DateFormatter
    
    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale.init(identifier: "zh_Hans_CN")
        formatter.calendar = Calendar.init(identifier: .iso8601) //in order to cope with potential 12-h format e.g. "上午 9:41"
        self.formatter = formatter
    }
    
    var body: some View {
        CalDimensionReader { dim in
            ZStack {
                ForEach(ClassTimeSlot.list) { timeSlot in
                    let point = CGPoint(x: dim.x / 2 + 5,
                                        y: dim.y - (dim.dy / 2) + CGFloat(timeSlot.id) * dim.dy)
                    TimeSlotView(id: timeSlot.id, start: formatter.string(from: timeSlot.start), end: formatter.string(from: timeSlot.end))
                        .position(point)
                }
            }
            .frame(width: dim.x, height: dim.y + CGFloat(h) * dim.dy)
            .frame(width: dim.x, height: dim.y + CGFloat(h) * dim.dy)
        }
    }
}

fileprivate struct TimeSlotView: View {
    @ScaledMetric private var courseSize = 14
    @ScaledMetric private var timeSize = 9
    
    let id: Int
    let start: String
    let end: String

    var body: some View {
        VStack {
            Text(String(id))
                .font(.system(size: courseSize))
                .bold()
            Group {
                Text(start)
                Text(end)
            }
            .font(.system(size: timeSize))
        }
        .foregroundColor(.secondary)
    }
}

struct GridBackground: View {
    let width: Int
    private let h = ClassTimeSlot.list.count
    
    var body: some View {
        CalDimensionReader { dim in
            Canvas { context, _ in
                let separatorColor = Color.secondary.opacity(0.2)
                
                // draw horizontal lines
                for i in 0...h {
                    let start = CGPoint(x: 0, y: CGFloat(i) * dim.dy)
                    let end = CGPoint(x: CGFloat(width) * dim.dx, y: CGFloat(i) * dim.dy)
                    let path = Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    context.stroke(path, with: .color(separatorColor))
                }
                
                // draw vertical lines
                for i in 0...width {
                    let start = CGPoint(x: CGFloat(i) * dim.dx, y: 0)
                    let end = CGPoint(x: CGFloat(i) * dim.dx, y: CGFloat(h) * dim.dy)
                    let path = Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    context.stroke(path, with: .color(separatorColor))
                }
            }
            .frame(width: CGFloat(width) * dim.dx, height: CGFloat(h) * dim.dy)
        }
    }
}

// MARK: Environments

struct CourseTintKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

extension EnvironmentValues {
    var courseTint: Color? {
        get { self[CourseTintKey.self] }
        set { self[CourseTintKey.self] = newValue }
    }
}

struct CalDimension {
    let x: CGFloat
    let y: CGFloat
    let dx: CGFloat
    let dy: CGFloat
    
    init(x: CGFloat = CalendarConfig.x,
         y: CGFloat = CalendarConfig.y,
         dx: CGFloat = CalendarConfig.dx,
         dy: CGFloat = CalendarConfig.dy) {
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
    }
}

struct CalDimensionKey: EnvironmentKey {
    static let defaultValue = CalDimension()
}

extension EnvironmentValues {
    var calDimension: CalDimension {
        get { self[CalDimensionKey.self] }
        set { self[CalDimensionKey.self] = newValue }
    }
}

struct CalDimensionReader<Content: View>: View {
    @Environment(\.calDimension) private var dimension
    let content: (CalDimension) -> Content
    
    private struct Nested<NestedContent: View>: View {
        @ScaledMetric var x: CGFloat
        @ScaledMetric var y: CGFloat
        @ScaledMetric var dx: CGFloat
        @ScaledMetric var dy: CGFloat
        let calContent: (CalDimension) -> NestedContent
        
        var body: some View {
            calContent(CalDimension(x: x, y: y, dx: dx, dy: dy))
        }
    }
    
    var body: some View {
        Nested(x: dimension.x, y: dimension.y,
               dx: dimension.dx, dy: dimension.dy,
               calContent: content)
    }
}

// MARK: - Length Constants

struct CalendarConfig {
    static let x: CGFloat = 40
    static let y: CGFloat = 50
    static let dx: CGFloat = 60
    static let dy: CGFloat = 50
}

// MARK: - Random Color

public func randomColor(_ name: String) -> Color {
    let hashColorList = [
        Color.red,
        Color.pink,
        Color.purple,
        Color.blue,
        Color.cyan,
        Color.teal,
        Color.green,
        Color.orange,
        Color.brown,
    ]
    
    var sum = 0
    for c in name.utf16 {
        sum += Int(c)
    }
    sum %= hashColorList.count
    return hashColorList[sum]
}

