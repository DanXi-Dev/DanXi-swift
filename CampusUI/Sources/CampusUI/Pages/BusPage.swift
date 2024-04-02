import SwiftUI
import FudanKit
import ViewUtils

struct BusPage: View {
    var body: some View {
        AsyncContentView { () -> FDBusModel in
            let (workdayRoutes, holidayRoutes) = try await BusStore.shared.getCachedRoutes()
            return FDBusModel(workdayRoutes, holidayRoutes)
        } content: { model in
            BusPageContent(model)
        }
    }
}

fileprivate struct BusPageContent: View {
    @StateObject private var model: FDBusModel
    
    init(_ model: FDBusModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    func getTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let dateString = formatter.string(from: Date())
        return dateString
    }
    
    var body: some View {
        List {
            Section {
                Picker(selection: $model.type, label: Text("Type")) {
                    Text("Workday").tag(FDBusType.workday)
                    Text("Holiday").tag(FDBusType.holiday)
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Text("From")
                    Spacer()
                    
                    let startBinding = Binding<String>(
                        get: { model.start },
                        set: { newStart in
                            if newStart == model.end {
                                // User probably wants to swap start & end locations
                                // We use bindings as an "elegant" way of triggering swap when this happens
                                model.end = model.start
                            }
                            model.start = newStart
                        }
                    )
                    
                    Picker(selection: startBinding, label: Text("From")) {
                        ForEach(model.campusList, id: \.self) { campus in
                            Text(campus).tag(campus)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                HStack {
                    Text("To")
                    Spacer()
                    
                    let endBinding = Binding<String>(
                        get: { model.end },
                        set: { newEnd in
                            if newEnd == model.start {
                                // User probably wants to swap start & end locations
                                // We use bindings as an "elegant" way of triggering swap when this happens
                                model.start = model.end
                            }
                            model.end = newEnd
                        }
                    )
                    
                    Picker(selection: endBinding, label: Text("To")) {
                        ForEach(model.campusList, id: \.self) { campus in
                            Text(campus).tag(campus)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Toggle(isOn: $model.filterSchedule.animation()) {
                    Text("Show schedule after \(getTime())")
                }
            }
            
            Section {
                ForEach(model.filteredSchedules) { schedule in
                    BusRow(schedule)
                }
            } footer: {
                if model.filteredSchedules.isEmpty {
                    Text("No available schedule")
                }
            }
            .environmentObject(model)
        }
        .navigationTitle("Bus Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}


fileprivate struct BusRow: View {
    @EnvironmentObject private var model: FDBusModel
    let schedule: Schedule
    
    init(_ schedual: Schedule) {
        self.schedule = schedual
    }
    
    var body: some View {
        HStack {
            
            Text(schedule.time.formatted(date: .omitted, time: .shortened))
            
            Spacer()
            
            HStack {
                Text(schedule.start)
                Image(systemName: schedule.bidirectional ? "arrow.left.and.right" : "arrow.right")
                Text(schedule.end)
            }
            .foregroundColor(.secondary)
        }
        .foregroundColor(schedule.missed ? .secondary : .primary)
    }
}

// MARK: - Model

fileprivate enum FDBusType {
    case workday, holiday
}

fileprivate class FDBusModel: ObservableObject {
    let workdayRoutes: [Route]
    let holidayRoutes: [Route]
    let campusList = ["邯郸", "江湾", "枫林", "张江"]
    @Published var start = "邯郸"
    @Published var end = "江湾"
    @Published var filterSchedule = true
    @Published var type = FDBusType.workday
    
    static func isWeekend() -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        return calendar.isDateInWeekend(currentDate)
    }
    
    init(_ workdayRoutes: [Route], _ holidayRoutes: [Route]) {
        self.workdayRoutes = workdayRoutes
        self.holidayRoutes = holidayRoutes
        self.type = FDBusModel.isWeekend() ? .holiday : .workday
    }
    
    var filteredSchedules: [Schedule] {
        let routes = type == .holiday ? holidayRoutes : workdayRoutes
        
        let route = routes.filter { route in
            let directMatch = route.start == start && route.end == end
            let reversedMatch = route.start == end && route.end == start
            return directMatch || reversedMatch
        }.first
        
        guard let route = route else {
            return []
        }
        
        var matchedSchedule = route.schedules.filter { schedule in
            schedule.start == start
        }
        
        let current = Date.now
        let calendar = Calendar.current
        matchedSchedule = matchedSchedule.map {
            var schedule = $0
            let components = calendar.dateComponents([.hour, .minute, .second], from: current)
            // the `current` date part is not the same with `schedule.time` date part
            // `current` need to be normalized before comparing
            if let normalizedCurrent = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: components.second ?? 0, of: schedule.time) {
                schedule.missed = schedule.time < normalizedCurrent
                return schedule
            }
            return schedule
        }
        
        if filterSchedule {
            matchedSchedule = matchedSchedule.filter { schedule in
                !schedule.missed
            }
        }
        
        return matchedSchedule
    }
    
    func swapLocation() {
        swap(&start, &end)
    }
}
