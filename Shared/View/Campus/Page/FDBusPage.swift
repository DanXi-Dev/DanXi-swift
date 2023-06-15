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
    let routes: [FDBusRoute]
    
    private let campusList = ["邯郸", "江湾", "枫林", "张江"]
    @State private var start = "邯郸"
    @State private var end = "江湾"
    @State private var holiday = false
    
    private var filteredSchedules: [FDBusSchedule] {
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
    
    var body: some View {
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
                    BusRow(schedule: schedule)
                }
            }
        }
        .navigationTitle("Bus Schedule")
    }
}


fileprivate struct BusRow: View {
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
