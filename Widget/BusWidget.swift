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
            let currentTime = Date()
            let currentCalendar = Calendar.current
            let startPoint = configuration.startPoint
            let endPoint = configuration.endPoint
            var entryList: [BusEntry] = [BusEntry(nil, currentTime, startPoint.rawValue, endPoint.rawValue)]
            
            let routes = currentCalendar.isDateInWeekend(currentTime) ? holidayRoutes : workdayRoutes
            
            // the routes.start/end from server only has one direction, for example only 邯郸->江湾 but not 江湾->邯郸.
            // so we need to filter the routes by both directions now.
            if let filteredRoutes = routes.filter({ ($0.start == startPoint.rawValue && $0.end == endPoint.rawValue) ||
                ($0.start == endPoint.rawValue && $0.end == startPoint.rawValue)
            }).first {
                // use the route time as render time
                let route = filteredRoutes.setSchedulesToBaseDate(date: currentTime)
                entryList = route.schedules.map { schedule in
                    BusEntry(route, schedule.time, startPoint.rawValue, endPoint.rawValue)
                }
            }
                
            let refreshDate = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
            let timeline = Timeline(entries: entryList, policy: .after(refreshDate))
            return timeline
        } catch {
            var entry = BusEntry(nil, Date(), configuration.startPoint.rawValue, configuration.endPoint.rawValue)
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
        let busTimeComponents = currentCalendar.dateComponents([.hour, .minute, .second], from: self.time)
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
    public let start, end: String
    public var placeholder = false
    public var loadFailed = false
    
    public init() {
        let date1 = Calendar.current.date(byAdding: .minute, value: 15, to: Date.now)!
        let date2 = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
        self.date = Date()
        self.route = Route(start: "邯郸", end: "枫林", schedules: [
            Schedule(id: 0, time: date1, start: "邯郸", end: "枫林", holiday: false, bidirectional: false),
            Schedule(id: 1, time: date2, start: "邯郸", end: "枫林", holiday: false, bidirectional: false)])
        self.start = "邯郸"
        self.end = "枫林"
    }
    
    public init(_ route: FudanKit.Route?, _ renderTime: Date, _ start: String, _ end: String) {
        self.date = renderTime
        self.route = route
        self.start = start
        self.end = end
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
                Text(self.entry.start)
                Text("至 ") + Text(self.entry.end)
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
        let timeNow = Date()
        
        if let route = entry.route {
            let schedules: [Schedule] = route.schedules.filter { schedule in
                schedule.time > timeNow && schedule.start == entry.start && schedule.end == entry.end
            }
            
            if let schedule = schedules.first {
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
                            
                    if let followingBus = schedules.dropFirst().first {
                        Group {
                            Text("下一班 ") + Text(formatter.string(from: followingBus.time))
                        }
                        .font(.caption2)
                        .foregroundColor(.gray)
                    } else {
                        Text("今日无更多班次")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.top, 1)
                    }
                })
            } else {
                return AnyView(Text("今日无更多班次")
                    .font(.footnote)
                    .foregroundColor(.gray))
            }
            
        } else {
            return AnyView(Text("无班次信息")
                            .font(.footnote)
                            .foregroundColor(.gray))
        }
    }
    
    var body: some View {
        if #available(iOS 17, *) {
            widgetContent
                .containerBackground(.fill, for: .widget)
        } else {
            self.widgetContent
                .padding()
        }
    }
    
    @ViewBuilder
    private var widgetContent: some View {
        if self.entry.loadFailed {
            Text("Load Failed")
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading) {
                self.header
                
                Spacer()
        
                self.followingBus
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
