import FudanKit
import SwiftUI
import WidgetKit
import Intents

struct BusWidgetProvier: IntentTimelineProvider {
    typealias Entry = BusEntry
    typealias Intent = BusScheduleIntent
    
    func placeholder(in context: Context) -> BusEntry {
        BusEntry()
    }
    
    func getSnapshot(for configuation: BusScheduleIntent, in context: Context, completion: @escaping (BusEntry) -> Void) {
        var entry = BusEntry()
        if !context.isPreview {
            entry.placeholder = true
        }
        completion(entry)
    }
    
    func getTimeline(for configuration: BusScheduleIntent, in context: Context, completion: @escaping (Timeline<BusEntry>) -> Void) {
        Task {
            do {
                let (workdayRoutes, holidayRoutes) = try await BusStore.shared.getRefreshedRoutes()
                let currentDate = Date()
                let calendar = Calendar.current
                
                let entry = BusEntry(calendar.isDateInWeekend(currentDate) ? holidayRoutes : workdayRoutes)
                
                let date = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            } catch {
                var entry = BusEntry()
                entry.loadFailed = true
                let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date.now)!
                let timeline = Timeline(entries: [entry], policy: .after(date))
                completion(timeline)
            }
        }
    }
}

public struct BusEntry: TimelineEntry {
    public let date: Date
    public let routes: [FudanKit.Route]
    public var placeholder = false
    public var loadFailed = false
    
    public init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm"
        let date1 = formatter.date(from: "2024-04-19 2:00")!
        let date2 = formatter.date(from: "2024-04-19 16:00")!
        date = Date()
        routes = [
            Route(start: "邯郸", end: "枫林", schedules: [
                Schedule(id: 0, time: date1, start: "邯郸", end: "枫林", holiday: false, bidirectional: false),
                Schedule(id: 0, time: date2, start: "邯郸", end: "枫林", holiday: false, bidirectional: false)])
        ]
    }
    
    public init(_ routes: [FudanKit.Route]) {
        date = Date()
        self.routes = routes
    }
}

//struct BusScheduleSelector: Widget {
//    let kind: String = "ecard.fudan.edu.cn"
//    public var body: some WidgetConfiguration {
//        IntentConfiguration(kind: kind, intent: BusScheduleIntent.self, provider: BusWidgetProvier()) { entry in
//            BusWidgetView(entry: entry)
//        }
//        .configurationDisplayName("Bus")
//        .description("Check school bus.")
//        .supportedFamilies([.systemSmall])
//    }
//}

public struct BusWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: "bus.fudan.edu.cn", intent: BusScheduleIntent.self, provider: BusWidgetProvier()) { entry in
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
        let route = entry.routes.filter { route in
            let directMatch = route.start == "邯郸" && route.end == "枫林"
            return directMatch
        }.first
        
        guard let route = route else {
            return AnyView(Text("No more bus"))
        }
            
        let timeNow = Date.now
        
        let schedules = route.schedules.filter { schedule in
            schedule.time > timeNow
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
                }
            })
        } else {
            return AnyView(Text("No more bus"))
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
