import SwiftUI
import MapKit
import FudanKit

@available(iOS 17.0, *)
struct LocationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var position: MapCameraPosition = .automatic
    @State private var item : MKMapItem?
    let location: String
    
    private func fetchLocation() async {
        let locationName = LocationManager.getLocationName(for: location)
        
        guard let mapItem = try? await LocationManager.searchLocation(locationName) else { return }
        
        await MainActor.run {
            self.item = mapItem
            self.position = .camera(MapCamera(centerCoordinate: mapItem.placemark.coordinate, distance: 400))
        }
    }
    
    
    var body: some View {
        NavigationStack {
            Map(position: $position) {
                Marker(location, systemImage: "building.fill", coordinate: item?.placemark.coordinate ?? CLLocationCoordinate2D())
            }
            .safeAreaInset(edge: .bottom){
                Button{
                    item?.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeCycling
                    ])
                }label: {
                    Image(systemName: "location")
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
        .task {
            await fetchLocation()
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
