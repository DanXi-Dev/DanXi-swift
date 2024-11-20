import SwiftUI
import DanXiKit
import FudanKit

struct AdvancedSettings: View {
    @ObservedObject private var settings = ForumSettings.shared
    @ObservedObject private var campusModel = CampusModel.shared
    @ObservedObject private var proxySettings = ProxySettings.shared
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settings.inAppBrowser) {
                    Text("Use in-app Browser", bundle: .module)
                }
            }
            
            Section {
                Toggle(isOn: $proxySettings.enableProxy) {
                    Text("Enable Campus Proxy", bundle: .module)
                }
                .disabled(!campusModel.loggedIn)
                .onAppear {
                    if !campusModel.loggedIn {
                        proxySettings.enableProxy = false
                    }
                }
            } footer: {
                Text("Use Fudan University WebVPN service to access Forum and DanKe from off-campus.\n\nWhen this is off, most features will only be available within the campus intranet. Campus Assistant automatically adjusts this setting based on your network condition. You do not have to change this in most occasions.", bundle: .module)
            }
        }
        .navigationTitle(String(localized: "Advanced Settings", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}
