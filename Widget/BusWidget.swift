import FudanKit
import Intents
import SwiftUI
import WidgetKit

struct BusWidgetProvier: AppIntentTimelineProvider {
    typealias Entry = BusEntry
    
    typealias Intent = BusScheduleIntent
    
    func placeholder(in context: Context) -> BusEntry {
        BusEntry()
    }
    
    func snapshot(for configuration: BusScheduleIntent, in context: Context) async -> BusEntry {
        var entry = BusEntry()
        let startPoint = configuration.startPoint
        print(startPoint.rawValue)
        if !context.isPreview {
            entry.placeholder = true
        }
        return entry
    }
    
    func timeline(for configuration: BusScheduleIntent, in context: Context) async -> Timeline<BusEntry> {
        do {
            let (workdayRoutes, holidayRoutes) = try await BusStore.shared.getRefreshedRoutes()
            let currentDate = Date()
            let currentCalendar = Calendar.current
            let startPoint = configuration.startPoint
            let endPoint = configuration.endPoint
            
            let routes = currentCalendar.isDateInWeekend(currentDate) ? holidayRoutes : workdayRoutes
            let filteredRoutes = routes.filter { $0.start == startPoint.rawValue && $0.end == endPoint.rawValue }.first
            
            for var schedule in filteredRoutes!.schedules {
                let dateComponents = currentCalendar.dateComponents([.year, .month, .day], from: .now)
                let busTimeComponents = currentCalendar.dateComponents([.hour, .minute, .second], from: schedule.time)
    
                var combinedComponents = DateComponents()
                combinedComponents.year = dateComponents.year
                combinedComponents.month = dateComponents.month
                combinedComponents.day = dateComponents.day
                combinedComponents.hour = busTimeComponents.hour
                combinedComponents.minute = busTimeComponents.minute
                combinedComponents.second = busTimeComponents.second

                schedule.time = currentCalendar.date(from: combinedComponents)!
            }
                
            let entry = BusEntry(filteredRoutes)
                
            let date = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
            let timeline = Timeline(entries: [entry], policy: .after(date))
            return timeline
        } catch {
            var entry = BusEntry()
            entry.loadFailed = true
            let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
            let timeline = Timeline(entries: [entry], policy: .after(date))
            return timeline
        }
    }
}

extension Schedule {
    func setBaseDate(date: Date) -> Schedule {
        let currentCalendar = Calendar.current
        let dateComponents = currentCalendar.dateComponents([.year, .month, .day], from: .now)
        let busTimeComponents = currentCalendar.dateComponents([.hour, .minute, .second], from: time)
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = busTimeComponents.hour
        combinedComponents.minute = busTimeComponents.minute
        combinedComponents.second = busTimeComponents.second

        if let currentScheduleTime = currentCalendar.date(from: combinedComponents) {
            return Schedule(id: self.id, time: currentScheduleTime, start: self.start, end: self.end, holiday: self.holiday, bidirectional: self.bidirectional, missed: self.missed)
        }
        
        print("Error: Failed to set base date for schedule.")
        return self
    }
}

extension Route {
    func setSchedulesToBaseDate(date: Date) -> Route {
        let start = self.start, end = self.end
        let schedules = self.schedules.map { $0.setBaseDate(date: date) }
        return Route(start: start, end: end, schedules: schedules)
    }
}

public struct BusEntry: TimelineEntry {
    public let date: Date
    public let route: FudanKit.Route?
    public var placeholder = false
    public var loadFailed = false
    
    public init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm"
        let date1 = formatter.date(from: "2024-04-19 2:00")!
        let date2 = formatter.date(from: "2024-04-19 16:00")!
        date = Date()
        route = Route(start: "邯郸", end: "枫林", schedules: [
            Schedule(id: 0, time: date1, start: "邯郸", end: "枫林", holiday: false, bidirectional: false),
            Schedule(id: 0, time: date2, start: "邯郸", end: "枫林", holiday: false, bidirectional: false)])
    }
    
    public init(_ route: FudanKit.Route?) {
        date = Date()
        self.route = route
    }
}


public struct BusWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "bus.fudan.edu.cn", intent: BusScheduleIntent.self, provider: BusWidgetProvier()) { entry in
            if #available(iOS 17.0, *) {
                BusWidgetView(entry: entry)
                    .containerBackground(.fill.quinary, for: .widget)
            } else {
                BusWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Bus")
        .description("Check school bus.")
        .supportedFamilies([.systemSmall])
    }
}

struct BusWidgetView: View {
    let entry: BusEntry
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("邯郸")
                Text("至 枫林")
            }
            .font(.callout)
            .fontWeight(.bold)
            Spacer()
            Image(systemName: "bus.fill")
                .foregroundColor(.cyan)
                .font(.callout)
                .fontWeight(.bold)
        }
    }
    
    private var followingBus: some View {
        
        guard entry.route != nil else {
            return AnyView(Text("No more bussss"))
        }
            
        let timeNow = Date.now
        
        let schedules = entry.route?.schedules.filter { schedule in
            schedule.time > timeNow
        }
        
        if let schedule = schedules?.first {
            // TODO: add 'if show nex day's bus' switch
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            formatter.locale = Locale.current
            // TODO: check if 12-hour format is working
            
            return AnyView(VStack(alignment: .leading, spacing: 2) {
                Text(formatter.string(from: schedule.time))
                    .font(.title2)
                    .fontWeight(.bold)
                Group {
                    Text("还有 ") + Text(schedule.time, style: .relative)
                }
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.cyan)
                
                if let followingBus = schedules?.dropFirst().first {
                    Group {
                        Text("下一班 ") + Text(formatter.string(from: followingBus.time))
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                } else {
                    Text("今日无更多班次")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            })
        } else {
            return AnyView(Text("No more"))
        }
    }
    
    var body: some View {
        if #available(iOS 17, *) {
            widgetContent
                .containerBackground(.fill, for: .widget)
        } else {
            widgetContent
                .padding()
        }
    }
    
    @ViewBuilder
    private var widgetContent: some View {
        if entry.loadFailed {
            Text("Load Failed")
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading) {
                header
                
                Spacer()
        
                followingBus
            }
        }
    }
}

@available(iOS 17, *)
#Preview("Bus", as: .systemSmall) {
    BusWidget()
} timeline: {
    BusEntry()
}
