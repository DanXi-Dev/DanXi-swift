import SwiftUI
import MapKit
import FudanKit

@available(iOS 17.0, *)
struct LocationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var showAlert = false
    @State var item : MKMapItem?
    @State var errorMessage : String?
    let location: String
    
    func generatePlaceName(for location: String)->String{
        let base = "复旦大学"
        
        let table: [(prefix: String, name: String)] = [
            (Building.hgx.rawValue, "光华楼西辅楼"),
            (Building.hgd.rawValue, "光华楼东辅楼"),
            (Building.h6.rawValue,  "第六教学楼"),
            (Building.h5.rawValue,  "第五教学楼"),
            (Building.h4.rawValue,  "第四教学楼"),
            (Building.h3.rawValue,  "第三教学楼"),
            (Building.h2.rawValue,  "第二教学楼"),
            (Building.hq.rawValue,  "新闻学院"),
            (Building.j.rawValue,   "江湾校区"),
            (Building.z.rawValue,   "张江校区"),
            (Building.f.rawValue,   "枫林校区")
        ]
        
        if let match = table.first(where: { location.hasPrefix($0.prefix) }) {
            return base + match.name + String(location.dropFirst(match.prefix.count))
        }
        
        return base + location.dropFirst(1)
    }
    
    func fetchCoordinate(for placeName: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = placeName
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard error == nil else {
                errorMessage = error!.localizedDescription
                showAlert = true
                return
            }
            if (response?.mapItems.first?.placemark.coordinate) != nil {
                self.item = response?.mapItems.first
            } else {
                showAlert = true
                errorMessage = nil
            }
        }
    }
    
    
    var body: some View {
        NavigationStack {
            Map{
                Marker(location,systemImage: "building.fill",coordinate: item?.placemark.coordinate ?? CLLocationCoordinate2D())
            }
            .safeAreaInset(edge: .bottom){
                Button{
                    item?.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeCycling
                    ])
                }label: {
                    Text(String(localized: "Get Directions", bundle: .module))
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 10.0)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
        }
        .alert(String(localized: "Location not found", bundle: .module), isPresented: $showAlert){} message: {
            if errorMessage != nil {
                Text(errorMessage!)
            }
        }
        .onAppear{
            fetchCoordinate(for: generatePlaceName(for: location))
        }
    }
}

#Preview {
    List {
        
    }
    .sheet(isPresented: .constant(true)) {
        if #available(iOS 17.0, *) {
            LocationSheet(location: "H2220")
        }
    }
}
