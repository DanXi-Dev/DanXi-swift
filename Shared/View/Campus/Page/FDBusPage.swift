import SwiftUI

struct FDBusPage: View {
    var body: some View {
        AsyncContentView { () -> FDBusModel in
            let workdayRoutes = try await FDBusAPI.fetchBusRoutes()
            let holidayRoutes = try await FDBusAPI.fetchHolidayRoutes()
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
                    Picker(selection: $model.start, label: Text("From")) {
                        ForEach(model.campusList, id: \.self) { campus in
                            Text(campus).tag(campus)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
//                Button {
//                    model.swapLocation()
//                } label: {
//                    Image(systemName: "arrow.left.arrow.right")
//                }
//                .padding(.horizontal, 20)
                
                HStack {
                    Text("To")
                    Spacer()
                    Picker(selection: $model.end, label: Text("To")) {
                        ForEach(model.campusList, id: \.self) { campus in
                            Text(campus).tag(campus)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Toggle(isOn: $model.filterSchedule) {
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
    let schedule: FDBusSchedule
    
    init(_ schedual: FDBusSchedule) {
        self.schedule = schedual
    }
    
    var body: some View {
        HStack {
            if let time = schedule.startAt(from: model.start) {
                Text(time.formatted(date: .omitted, time: .shortened))
            }
            
            Spacer()
            
            HStack {
                Text(schedule.start)
                switch schedule.arrow {
                case 1:
                    Image(systemName: "arrow.left.and.right")
                case 2:
                    Image(systemName: "arrow.left")
                case 3:
                    Image(systemName: "arrow.right")
                default:
                    EmptyView()
                }
                Text(schedule.end)
            }
            .foregroundColor(.secondary)
        }
        .foregroundColor(schedule.missed ? .secondary : .primary )
    }
}

// MARK: - Model

fileprivate enum FDBusType {
    case workday, holiday
}

fileprivate class FDBusModel: ObservableObject {
    let workdayRoutes: [FDBusRoute]
    let holidayRoutes: [FDBusRoute]
    let campusList = ["邯郸", "江湾", "枫林", "张江"]
    @Published var start = "邯郸"
    @Published var end = "江湾"
    @Published var filterSchedule = true
    @Published var type = FDBusType.workday
    
    init(_ workdayRoutes: [FDBusRoute], _ holidayRoutes: [FDBusRoute]) {
        self.workdayRoutes = workdayRoutes
        self.holidayRoutes = holidayRoutes
    }
    
    var filteredSchedules: [FDBusSchedule] {
        let routes = type == .holiday ? holidayRoutes : workdayRoutes
        
        let route = routes.filter { route in
            route.match(start: start, end: end)
        }.first
        
        guard let route = route else {
            return []
        }
        
        var matchedSchedule = route.lists.filter { schedual in
            schedual.match(start: start, end: end)
        }
        
        let current = Date.now
        let calendar = Calendar.current
        matchedSchedule = matchedSchedule.map {
            var schedule = $0
            if let startTime = schedule.startAt(from: start) {
                let components = calendar.dateComponents([.hour, .minute, .second], from: current)
                if let modifiedCurrent = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: components.second ?? 0, of: startTime) {
                    schedule.missed = startTime < modifiedCurrent
                    return schedule
                }
            }
            schedule.missed = true
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
