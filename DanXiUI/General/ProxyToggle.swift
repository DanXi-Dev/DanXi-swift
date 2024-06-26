import SwiftUI
import DanXiKit
import FudanKit

struct ProxyToggle: View {
    @ObservedObject private var campusModel = CampusModel.shared
    @ObservedObject private var proxySettings = ProxySettings.shared
    
    var body: some View {
        Toggle(isOn: $proxySettings.enableProxy) {
            Label {
                Text("Enable Campus Proxy", bundle: .module)
            } icon: {
                Image(systemName: "network")
            }
        }
        .disabled(!campusModel.loggedIn)
        .onAppear {
            if !campusModel.loggedIn {
                proxySettings.enableProxy = false
            }
        }
    }
}
