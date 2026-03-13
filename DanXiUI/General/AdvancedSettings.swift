import SwiftUI
import DanXiKit
import FudanKit
import Disk
import KeychainAccess
import Utils
import PulseUI

struct AdvancedSettings: View {
    @ObservedObject private var settings = ForumSettings.shared
    @ObservedObject private var campusModel = CampusModel.shared
    @ObservedObject private var proxySettings = ProxySettings.shared
    @AppStorage("record-network") private var recordNetwork = false
    @State private var showClearAllCacheWarning = false
    @State private var showRestartRequiredCover = false
    @State private var showPulseConsole = false
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settings.inAppBrowser) {
                    Text("Use in-app Browser", bundle: .module)
                }
            
                Toggle(isOn: $settings.showBanners) {
                    Text("Show Banners", bundle:.module)
                }
            } footer: {
                Text("Control whether to show activity banners at the top of the forum page.", bundle: .module)
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

            Section {
                Toggle(isOn: recordNetworkBinding) {
                    Text("Record Network Activity", bundle: .module)
                }

                if recordNetwork {
                    Button {
                        showPulseConsole = true
                    } label: {
                        Text("Open Network Console", bundle: .module)
                    }
                }
            } footer: {
                Text("When enabled, the app records network activity for debugging.", bundle: .module)
            }
            
             previewFeatureSetting
            
            Section {
                Button {
                    Task.detached {
                        try Disk.remove("cachedimages/", from: .caches)
                    }
                } label: {
                    Text("Clear Image Cache", bundle: .module)
                }
            } footer: {
                Text("Clear image cache to free up disk space.", bundle: .module)
            }
            
            Section {
                Button(role: .destructive) {
                    showClearAllCacheWarning = true
                } label: {
                    Text("Clear All Data", bundle: .module)
                }
            } footer: {
                Text("Clear all local data, including login accounts, search history, image cache, calendar and course cache, etc. It is generally used to fix issues such as freezing or failure to load content. This operation cannot be undone, so please use it under the guidance of the development team.", bundle: .module)
            }
            
        }
        .alert(String(localized: "Confirm Clearing All Data", bundle: .module), isPresented: $showClearAllCacheWarning) {
            Button(role: .destructive) {
                Task.detached {
                    try? Disk.remove("fduhole/", from: .appGroup)
                    try? Disk.remove("fdutools/", from: .appGroup)
                    try? Disk.remove("cachedimages/", from: .caches)
                    let communityKeychain = Keychain(service: "com.fduhole.danxi")
                    communityKeychain[data: "token"] = nil
                    let campusKeychain = Keychain(service: "com.fduhole.fdutools", accessGroup: "group.com.fduhole.danxi")
                    campusKeychain["username"] = nil
                    campusKeychain["password"] = nil
                    campusKeychain["campus-student-type"] = nil
                    
                    let defaults = UserDefaults.standard
                    let dictionary = defaults.dictionaryRepresentation()
                    dictionary.keys.forEach { key in
                        defaults.removeObject(forKey: key)
                    }
                    
                    exit(0) // close app to clear memory
                }
            } label: {
                Text("Clear All Data", bundle: .module)
            }
        } message: {
            Text("Clear all data. The app will restart after this operation.", bundle: .module)
        }
        .fullScreenCover(isPresented: $showRestartRequiredCover) {
            NavigationStack {
                VStack(spacing: 20) {
                    Spacer()
                    Text("Restart Required", bundle: .module)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Please quit and reopen the app to apply network recording changes.", bundle: .module)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                    Spacer()
                    Button(role: .destructive) {
                        exit(0)
                    } label: {
                        Text("Quit App", bundle: .module)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 20)

                    Button {
                        showRestartRequiredCover = false
                    } label: {
                        Text("Later", bundle: .module)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .navigationBarBackButtonHidden(true)
            }
        }
        .sheet(isPresented: $showPulseConsole) {
            NavigationStack {
                ConsoleView(mode: .network)
            }
        }
        .navigationTitle(String(localized: "Advanced Settings", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var recordNetworkBinding: Binding<Bool> {
        Binding {
            recordNetwork
        } set: { newValue in
            guard newValue != recordNetwork else {
                return
            }
            recordNetwork = newValue
            showRestartRequiredCover = true
        }
    }
    
    private var previewFeatureSetting: some View {
        Section {
            Picker(String(localized: "Preview Features", bundle: .module), selection: $settings.previewFeatureSetting) {
                Text("Show", bundle: .module).tag(ForumSettings.PreviewFeatureSetting.show)
                Text("Focus", bundle: .module).tag(ForumSettings.PreviewFeatureSetting.focus)
                Text("Hide", bundle: .module).tag(ForumSettings.PreviewFeatureSetting.hide)
            }
        } footer: {
            Text("Control the appearance of preview features, currently including innovation bank", bundle: .module)
        }
    }

}

#Preview {
    NavigationStack {
        AdvancedSettings()
    }
}
