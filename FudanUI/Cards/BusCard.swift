import SwiftUI
import FudanKit
import ViewUtils

struct BusCard: View {
    @Environment(\.scenePhase) var scenePhase
    @State private var contentId = UUID() // Controls refresh
    
    private let style = AsyncContentStyle {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(verbatim: "邯郸").redacted(reason: .placeholder)
                    Image(systemName: "arrow.right")
                    Text(verbatim: "江湾").redacted(reason: .placeholder)
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
                
                HStack {
                    Text(verbatim: "12:00")
                        .font(.headline)
                        .redacted(reason: .placeholder)
                    Group {
                        Text("Next: ", bundle: .module)
                        Text(verbatim: "12:00").redacted(reason: .placeholder)
                    }
                    .font(.footnote)
                    .bold()
                    .foregroundStyle(.cyan)
                }
            }
            
            Spacer()
        }
    } errorView: { error, retry in
        let errorDescription = (error as? LocalizedError)?.errorDescription ?? String(localized: "Loading Failed", bundle: .module)
        
        Button(action: retry) {
            Label(errorDescription, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.secondary)
                .font(.system(size: 15))
        }
        .padding(.bottom, 15)
    }
    
    private var isWeekend: Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        return calendar.isDateInWeekend(currentDate)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Image(systemName: "bus.fill")
                    Text("Bus Schedule", bundle: .module)
                    Spacer()
                }
                .bold()
                .font(.callout)
                .foregroundColor(.cyan)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Group {
                        if isWeekend {
                            Text("Holiday", bundle: .module)
                        } else {
                            Text("Workday", bundle: .module)
                        }
                    }
                    .foregroundStyle(.cyan)
                    .font(.system(size: 10))
                    .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(5)
                }
                                
                AsyncContentView(style: style, animation: .default) {
                    try await BusStore.shared.getCachedRoutes()
                } content: { (workdayRoutes, holidayRoutes) in
                    if #available(iOS 17.0, *) {
                        BusCardContent(workdayRoutes, holidayRoutes)
                            .id(contentId)
                            .onChange(of: scenePhase) { oldPhase, newPhase in
                                if oldPhase == .background {
                                    contentId = UUID()
                                }
                            }
                    } else {
                        BusCardContent(workdayRoutes, holidayRoutes)
                            .id(contentId)
                            .onChange(of: scenePhase) { newPhase in
                                if newPhase == .active {
                                    contentId = UUID()
                                }
                            }
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .bold()
                .font(.footnote)
        }
    }
}

private struct BusCardContentValue {
    let isWeekend: Bool
    let schedule, nextSchedule, reversedSchedule, nextReversedSchedule: Schedule?
    
    static func create(workday: [Route], holiday: [Route], start: String, end: String) -> BusCardContentValue? {
        let currentDate = Date()
        let calendar = Calendar.current
        let isWeekend = calendar.isDateInWeekend(currentDate)
        
        let routes = if isWeekend {
            holiday
        } else {
            workday
        }
        
        let route = routes.filter { route in
            let directMatch = route.start == start && route.end == end
            let reversedMatch = route.start == end && route.end == start
            return directMatch || reversedMatch
        }.first
        guard let route else { return nil }
        
        let schedules = route.schedules.filter { schedule in
            !schedule.missed && schedule.start == start
        }
        let schedule = schedules.first
        let nextSchedule = schedules.dropFirst().first
        
        let reversedSchedules = route.schedules.filter { schedule in
            !schedule.missed && schedule.start == end
        }
        let reversedSchedule = reversedSchedules.first
        let nextReversedSchedule = reversedSchedules.dropFirst().first
        
        return .init(
            isWeekend: isWeekend,
            schedule: schedule,
            nextSchedule: nextSchedule,
            reversedSchedule: reversedSchedule,
            nextReversedSchedule: nextReversedSchedule)
    }
}

private struct BusCardContent: View {
    @AppStorage("bus.start") private var start = "邯郸"
    @AppStorage("bus.end") private var end = "江湾"
    
    private let workdayRoutes: [Route]
    private let holidayRoutes: [Route]
    
    private var value: BusCardContentValue? {
        BusCardContentValue.create(workday: workdayRoutes, holiday: holidayRoutes, start: start, end: end)
    }
    
    private var schedule: Schedule? {
        value?.schedule
    }
    
    private var nextSchedule: Schedule? {
        value?.nextSchedule
    }
    
    private var reversedSchedule: Schedule? {
        value?.reversedSchedule
    }
    
    private var nextReversedSchedule: Schedule? {
        value?.nextReversedSchedule
    }
    
    init(_ workdayRoutes: [Route], _ holidayRoutes: [Route]) {
        self.workdayRoutes = workdayRoutes
        self.holidayRoutes = holidayRoutes
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(start)
                    Image(systemName: "arrow.right")
                    Text(end)
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
                
                HStack {
                    if let schedule {
                        HStack(alignment: .lastTextBaseline) {
                            Text(schedule.time.formatted(.dateTime.hour().minute().locale(Locale(identifier: "en_CN")))) //use "en_CN" in order to cope with potential 12-h format problem
                                .font(.headline)
                            if let nextSchedule {
                                Text("Next: \(nextSchedule.time.formatted(.dateTime.hour().minute().locale(Locale(identifier: "en_CN"))))", bundle: .module) //use "en_CN" in order to cope with potential 12-h format problem
                                    .font(.system(size: 11))
                                    .bold()
                                    .foregroundStyle(.cyan)
                            }
                        }
                    } else {
                        Text("Closed", bundle: .module)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(end)
                        Image(systemName: "arrow.right")
                        Text(start)
                    }
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    
                    if let reversedSchedule {
                        HStack(alignment: .lastTextBaseline) {
                            Text(reversedSchedule.time.formatted(.dateTime.hour().minute().locale(Locale(identifier: "en_CN")))) //use "en_CN" in order to cope with potential 12-h format problem
                                .font(.headline)
                            if let nextReversedSchedule {
                                Text("Next: \(nextReversedSchedule.time.formatted(.dateTime.hour().minute().locale(Locale(identifier: "en_CN"))))", bundle: .module) //use "en_CN" in order to cope with potential 12-h format problem
                                    .font(.system(size: 11))
                                    .bold()
                                    .foregroundStyle(.cyan)
                            }
                        }
                    } else {
                        Text("Closed", bundle: .module)
                            .font(.headline)
                    }
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    BusCard()
        .previewPrepared(wrapped: .card)
}
