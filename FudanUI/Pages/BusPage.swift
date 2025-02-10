import SwiftUI
import FudanKit
import ViewUtils

struct BusPage: View {
    var body: some View {
        AsyncContentView {
            let (workdayRoutes, holidayRoutes) = try await BusStore.shared.getCachedRoutes()
            return BusModel(workdayRoutes, holidayRoutes)
        } refreshAction: {
            let (workdayRoutes, holidayRoutes) = try await BusStore.shared.getRefreshedRoutes()
            return BusModel(workdayRoutes, holidayRoutes)
        } content: { model in
            BusPageContent(model)
        }
        .navigationTitle(String(localized: "Bus Schedule", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct BusPageContent: View {
    @StateObject private var model: BusModel
    
    #if os(watchOS)
    @State private var showControlSheet = false
    #endif
    
    init(_ model: BusModel) {
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
                #if os(watchOS)
                
                Button {
                    showControlSheet = true
                } label: {
                    LabeledContent {
                        Text(model.start) + Text(Image(systemName: "arrow.right")) + Text(model.end)
                    } label: {
                        Group {
                            switch model.type {
                            case .holiday:
                                Text("Holiday", bundle: .module)
                            case .workday:
                                Text("Workday", bundle: .module)
                            }
                        }
                    }
                }
                #else
                
                Picker(selection: $model.type, label: Text("Type", bundle: .module)) {
                    Text("Workday", bundle: .module).tag(BusType.workday)
                    Text("Holiday", bundle: .module).tag(BusType.holiday)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("From", bundle: .module)
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
                    Text("To", bundle: .module)
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
                    Text("Show schedule after \(getTime())", bundle: .module)
                }
                #endif
            }
            
            Section {
                ForEach(model.filteredSchedules) { schedule in
                    BusRow(schedule)
                }
            } footer: {
                if model.filteredSchedules.isEmpty {
                    Text("No available schedule", bundle: .module)
                }
            }
            .environmentObject(model)
        }
        #if os(watchOS)
        .sheet(isPresented: $showControlSheet) {
            controlSheet
        }
        #endif
    }
    
    #if os(watchOS)
    
    private var controlSheet: some View {
        List {
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
            
            Picker(selection: startBinding, label: Text("From", bundle: .module)) {
                ForEach(model.campusList, id: \.self) { campus in
                    Text(campus).tag(campus)
                }
            }
            
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
            
            Picker(selection: endBinding, label: Text("To", bundle: .module)) {
                ForEach(model.campusList, id: \.self) { campus in
                    Text(campus).tag(campus)
                }
            }
            
            Toggle(isOn: $model.filterSchedule.animation()) {
                Text("Show schedule after \(getTime())", bundle: .module)
            }
        }
    }
    
    #endif
}


fileprivate struct BusRow: View {
    @EnvironmentObject private var model: BusModel
    let schedule: Schedule
    
    init(_ schedule: Schedule) {
        self.schedule = schedule
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

fileprivate enum BusType {
    case workday, holiday
}

fileprivate class BusModel: ObservableObject {
    let workdayRoutes: [Route]
    let holidayRoutes: [Route]
    let campusList = ["邯郸", "江湾", "枫林", "张江"]
    @AppStorage("bus.start") var start = "邯郸"
    @AppStorage("bus.end") var end = "江湾"
    @Published var filterSchedule = true
    @Published var type = BusType.workday
    
    static func isWeekend() -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        return calendar.isDateInWeekend(currentDate)
    }
    
    init(_ workdayRoutes: [Route], _ holidayRoutes: [Route]) {
        self.workdayRoutes = workdayRoutes
        self.holidayRoutes = holidayRoutes
        self.type = BusModel.isWeekend() ? .holiday : .workday
    }
    
    var filteredSchedules: [Schedule] {
        let routes = type == .holiday ? holidayRoutes : workdayRoutes
        
        let route = routes.filter { route in
            let directMatch = route.start == start && route.end == end
            let reversedMatch = route.start == end && route.end == start
            return directMatch || reversedMatch
        }.first
        
        guard let route else { return [] }
        
        var matchedSchedule = route.schedules.filter { schedule in
            schedule.start == start
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

#Preview {
    BusPage()
        .previewPrepared()
}
