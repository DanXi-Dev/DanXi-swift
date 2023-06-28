import SwiftUI

struct FDBusPage: View {
    var body: some View {
        AsyncContentView {
            return try await FDBusAPI.fetchBusRoutes()
        } content: { routes in
            BusPageContent(routes: routes)
        }
    }
}

fileprivate struct BusPageContent: View {
    @StateObject private var model: FDBusModel
    
    init(routes: [FDBusRoute]) {
        self._model = StateObject(wrappedValue: FDBusModel(routes))
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Picker(selection: $model.start, label: Text("From")) {
                        ForEach(model.campusList, id: \.self) { campus in
                            Text(campus).tag(campus)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        model.swapLocation()
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    
                    Spacer()
                    
                    Picker(selection: $model.end, label: Text("To")) {
                        ForEach(model.campusList, id: \.self) { campus in
                            Text(campus).tag(campus)
                        }
                    }
                }
                .buttonStyle(.borderless)
                Toggle(isOn: $model.showMissed) {
                    Text("Show all schedule")
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

fileprivate class FDBusModel: ObservableObject {
    let routes: [FDBusRoute]
    let campusList = ["邯郸", "江湾", "枫林", "张江"]
    @Published var start = "邯郸"
    @Published var end = "江湾"
    @Published var showMissed = false
    @Published var holiday = false
    
    init(_ routes: [FDBusRoute]) {
        self.routes = routes
    }
    
    var filteredSchedules: [FDBusSchedule] {
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
        
        if !showMissed {
            matchedSchedule = matchedSchedule.filter { schedule in
                !schedule.missed
            }
        }
        
        // TODO: holiday
        
        return matchedSchedule
    }
    
    func swapLocation() {
        swap(&start, &end)
    }
}
