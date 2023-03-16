import SwiftUI

struct FDBusPage: View {
    
    @State var routes: [FDBusRoute] = []
    
    let campusList = ["邯郸", "江湾", "枫林", "张江"]
    
    @State var start = "邯郸"
    @State var end = "江湾"
    @State var holiday = false
    
    
    var filteredSchedules: [FDBusSchedule] {
        let route = routes.filter { route in
            route.match(start: start, end: end)
        }.first
        
        guard let route = route else {
            return []
        }
        
        return route.lists.filter { schedual in
            schedual.match(start: start, end: end)
        }
    }
    
    func loadRoutes() async throws {
        self.routes = try await FDBusAPI.fetchBusRoutes()
    }
    
    var body: some View {
        LoadingPage(action: loadRoutes) {
            List {
                Section {
                    Picker(selection: $start, label: Text("From")) {
                        ForEach(campusList, id: \.self) { campus in
                            Text(campus + "校区").tag(campus)
                        }
                    }
                    
                    Picker(selection: $end, label: Text("To")) {
                        ForEach(campusList, id: \.self) { campus in
                            Text(campus + "校区").tag(campus)
                        }
                    }
                }
                
                Section {
                    ForEach(filteredSchedules) { schedule in
                        FDScheduleView(schedule: schedule)
                    }
                }
            }
            .navigationTitle("Bus Schedule")
        }
    }
}


struct FDScheduleView: View {
    let schedule: FDBusSchedule
    
    var body: some View {
        HStack {
            VStack {
                Text(schedule.start + "校区")
                Text(schedule.startTime?.formatted(date: .omitted, time: .shortened) ?? " ")
            }
            
            Spacer()
            
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
            
            Spacer()
            
            VStack {
                Text(schedule.end + "校区")
                Text(schedule.endTime?.formatted(date: .omitted, time: .shortened) ?? " ")
            }
        }
    }
}

struct FDBusPage_Previews: PreviewProvider {
    static var previews: some View {
        FDBusPage()
    }
}
