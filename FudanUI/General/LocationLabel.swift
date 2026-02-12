import SwiftUI
import FudanKit

public struct LocationLabel: View {
    let location: String
    @State private var locationFound = false
    @State private var showLocationSheet = false
    
    public init(location: String) {
        self.location = location
    }
    
    public var body: some View {
        Group {
            if #available(iOS 17.0, *), locationFound {
                Button {
                    showLocationSheet = true
                } label: {
                    Text(location)
                }
            } else {
                Text(location)
            }
        }
        .task {
            if #available(iOS 17.0, *) {
                locationFound = await LocationManager.validateLocation(location)
            }
        }
        .sheet(isPresented: $showLocationSheet) {
            if #available(iOS 17.0, *) {
                LocationSheet(location: location)
            }
        }
    }
}
