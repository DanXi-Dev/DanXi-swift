import Foundation

/// API collection for school bus service
///
/// The server responds with a list of collections. Each collection represents a
/// bus route, and has a `list` property containing multiple bus schedule.
///
/// The response data structure is as follows:
/// ```json
///{
///"collect": 0,
///"route": "枫林-江湾",
///"lists": [
///  {
///    "id": "130071",
///    "start": "枫林",
///    "end": "江湾",
///    "stime": "",
///    "etime": "6:45",
///    "arrow": "2",
///    "holiday": "0"
///  },
///  ...
/// ]
///}
/// ```
/// The `arrow` property can be quite confusing. It has 3 possible value:
/// - 3: The bus schedule is `start -> end`, start at `stime`, and `etime` will be empty.
/// - 2: The bus schedule is `start <- end`, start at `etime`, and `stime` will be empty.
/// - 1: The bus schedule is `start <-> end`, bus departing from start leaves at `stime`, bus departing from end leaves at `etime`.
///
/// - Important
/// In some cases, the separator between hour and minute can be `.`, example is shown as follows:
/// ```json
/// {
///    "id": "130046",
///    "start": "邯郸",
///    "end": "张江",
///    "stime": "14.30",
///    "etime": "",
///    "arrow": "3",
///    "holiday": "0"
/// },
/// ```
public enum BusAPI {
    public enum DateType {
        case workday, holiday
    }
    
    
    /// Get bus routes.
    /// - Parameter type: `.workday` or `.holiday
    public static func getRoutes(type: DateType) async throws -> [Route] {
        // fetch data from server
        
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanbus/wap/default/lists")!
        var routeResponses: [RouteResponse] = []
        switch type {
        case .workday:
            let data = try await Authenticator.shared.authenticate(url)
            let routeData = try unwrapJSON(data)["data"].rawData()
            routeResponses = try JSONDecoder().decode([RouteResponse].self, from: routeData)
        case .holiday:
            let request = constructFormRequest(url, form: ["holiday": "1"])
            let data = try await Authenticator.shared.authenticate(request)
            let routeData = try unwrapJSON(data)["data"].rawData()
            routeResponses = try JSONDecoder().decode([RouteResponse].self, from: routeData)
        }
        
        // convert response into data objects
        
        return routeResponses.map { routeResponse in
            let stops = routeResponse.route.split(separator: "-")
            let start = String(stops[0])
            let end = String(stops[1])
            
            var schedules: [Schedule] = []
            
            let dateDecoder = DateFormatter()
            dateDecoder.dateFormat = "HH:mm"
            
            for scheduleResponse in routeResponse.lists {
                let startTimeString = scheduleResponse.stime.replacing(".", with: ":")
                let endTimeString = scheduleResponse.etime.replacing(".", with: ":")
                guard let id = Int(scheduleResponse.id) else {
                    continue
                }
                let holiday = scheduleResponse.holiday == "0"
                
                switch scheduleResponse.arrow {
                case "3":
                    guard let time = dateDecoder.date(from: startTimeString) else { continue }
                    let start = scheduleResponse.start
                    let end = scheduleResponse.end
                    let schedule = Schedule(id: id, time: time, start: start, end: end, holiday: holiday, bidirectional: false)
                    schedules.append(schedule)
                case "2":
                    guard let time = dateDecoder.date(from: endTimeString) else { continue }
                    let start = scheduleResponse.end
                    let end = scheduleResponse.start
                    let schedule = Schedule(id: id, time: time, start: start, end: end, holiday: holiday, bidirectional: false)
                    schedules.append(schedule)
                case "1":
                    // expand bidirectional bus schedule into 2 separate schedules
                    guard let stime = dateDecoder.date(from: startTimeString) else { continue }
                    guard let etime = dateDecoder.date(from: endTimeString) else { continue }
                    let forward = Schedule(id: id, time: stime, start: start, end: end, holiday: holiday, bidirectional: true)
                    let backward = Schedule(id: id, time: etime, start: end, end: start, holiday: holiday, bidirectional: true)
                    schedules += [forward, backward]
                default:
                    continue
                }
            }
            
            return Route(start: start, end: end, schedules: schedules)
        }
    }
    
    private struct RouteResponse: Codable {
        let route: String
        let lists: [ScheduleResponse]
    }

    private struct ScheduleResponse: Codable {
        let id: String
        let start: String
        let end: String
        let stime: String
        let etime: String
        let arrow: String
        let holiday: String
    }
}
