import SwiftUI
import FudanKit
import FudanUI
import DanXiKit
import DanXiUI
import Utils
import ViewUtils

struct SettingsPage: View {
    @EnvironmentObject private var navigator: AppNavigator
    @ObservedObject private var communityModel = CommunityModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    
    @State private var communityLoginSheet = false
    @State private var communityUserSheet = false
    @State private var campusLoginSheet = false
    @State private var campusUserSheet = false
    
    var showToolbar: Bool {
        campusModel.loggedIn || communityModel.loggedIn
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                EmptyView()
                    .id("settings-top")
                
                Section("Accounts Management") {
                    CampusAccountButton(showLoginSheet: $campusLoginSheet, showUserSheet: $campusUserSheet)
                    
                    CommunityAccountButton(showLoginSheet: $communityLoginSheet, showUserSheet: $communityUserSheet)
                }
                
                CampusSettingsView()
                
                if communityModel.loggedIn {
                    ForumSettingsView()
                }
                
                Section {
                    DetailLink(value: ForumSettingsSection.advancedSettings) {
                        ForumSettingsSection.advancedSettings.label.navigationStyle()
                    }
                    
                    DetailLink(value: SettingsSection.about) {
                        Label("About", systemImage: "info.circle")
                            .navigationStyle()
                    }
                    
                    NavigationLink {
                        EntryViewer()
                    } label: {
                        Label("Debug Information", systemImage: "ecg.text.page")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onReceive(AppEvents.ScrollToTop.settings) { _ in
                withAnimation {
                    proxy.scrollTo("settings-top")
                }
            }
            .onReceive(AppEvents.notificationSettings) { content in
                navigator.pushDetail(value: ForumSettingsSection.notification, replace: true)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $communityLoginSheet) {
            DanXiUI.AuthenticationSheet()
        }
        .sheet(isPresented: $communityUserSheet) {
            DanXiUI.CommunityAccountSheet()
        }
        .sheet(isPresented: $campusUserSheet) {
            FudanUI.AccountSheet()
        }
        .sheet(isPresented: $campusLoginSheet) {
            FudanUI.LoginSheet()
        }
        .toolbar(showToolbar ? .visible : .hidden, for: .tabBar)
    }
}

struct EntryViewer: View {
    @ObservedObject private var entryRecorder = EntryRecorder.shared
    
    var body: some View {
        List {
            ForEach(entryRecorder.records) { record in
                VStack(alignment: .leading) {
                    Text(record.content)
                    HStack {
                        Text(verbatim: "\(record.file):\(record.line)")
                        Spacer()
                        Text(record.date.formatted(date: .omitted, time: .shortened))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
