import MapKit

public struct LocationManager {
    static let campusTable: [Character: (name: String, radius: CLLocationDistance)] = [
        "J": ("复旦大学江湾校区", 900),
        "Z": ("复旦大学张江校区", 450),
        "F": ("复旦大学枫林校区", 350),
        "H": ("复旦大学邯郸校区", 1000)
    ]
    
    public static func getCampusName(for location: String) -> String {
        return campusTable[location.first ?? "H"]?.name ?? campusTable["H"]!.name
    }
    
    public static func getCampusRadius(for location: String) -> CLLocationDistance {
        return campusTable[location.first ?? "H"]?.radius ?? campusTable["H"]!.radius
    }
    
    static let locationTable: [(prefix: String, name: String)] = [
        (Building.hgx.rawValue, "光华楼西辅楼"),
        (Building.hgd.rawValue, "光华楼东辅楼"),
        (Building.h6.rawValue,  "第六教学楼"),
        (Building.h5.rawValue,  "第五教学楼"),
        (Building.h4.rawValue,  "第四教学楼"),
        (Building.h3.rawValue,  "第三教学楼"),
        (Building.h2.rawValue,  "第二教学楼"),
        ("JA", "江湾校区教学楼A号楼"),
        ("JB", "江湾校区智华楼"),
        ("Z1", "张江校区1号教学楼"),
        ("Z2", "张江校区2号教学楼"),
        ("F1", "上海医学院第1教学楼"),
        ("F2", "上海医学院第2教学楼"),
        ("H", "邯郸校区"),
        (Building.hq.rawValue,  "新闻学院"),
        (Building.j.rawValue,   "江湾校区"),
        (Building.z.rawValue,   "张江校区"),
        (Building.f.rawValue,   "枫林校区")
    ]
    
    public static func getLocationName(for location: String) -> String {
        let base = "复旦大学"
        if let match = locationTable.first(where: { location.hasPrefix($0.prefix) }) {
            return base + match.name + String(location.dropFirst(match.prefix.count))
        }
        return base + location.dropFirst(1)
    }
    
    public static func searchLocation(_ query: String) async throws -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.first
    }
    
    public static func validateLocation(_ location: String) async -> Bool {
        guard !location.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        let campusName = getCampusName(for: location)
        let locationName = getLocationName(for: location)
        
        do {
            guard let campusCoordinate = try await searchLocation(campusName)?.placemark.coordinate,
                  let locationCoordinate = try await searchLocation(locationName)?.placemark.coordinate else {
                return false
            }
            
            let campusLocation = CLLocation(latitude: campusCoordinate.latitude, longitude: campusCoordinate.longitude)
            let targetLocation = CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
            return targetLocation.distance(from: campusLocation) <= getCampusRadius(for: location)
        } catch {
            return false
        }
    }
}
