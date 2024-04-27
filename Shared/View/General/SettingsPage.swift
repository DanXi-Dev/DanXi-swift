import SwiftUI
import FudanKit
import FudanUI
import Utils
import ViewUtils

struct SettingsPage: View {
    @EnvironmentObject private var navigator: AppNavigator
    @ObservedObject private var forumModel = DXModel.shared
    @ObservedObject private var campusModel = CampusModel.shared
    
    @State private var forumLoginSheet = false
    @State private var forumUserSheet = false
    @State private var campusLoginSheet = false
    @State private var campusUserSheet = false
    
    var showToolbar: Bool {
        campusModel.loggedIn || forumModel.isLogged
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                EmptyView()
                    .id("settings-top")
                
                Section("Accounts Management") {
                    CampusAccountButton(showLoginSheet: $campusLoginSheet, showUserSheet: $campusUserSheet)
                    
                    Button {
                        if forumModel.isLogged {
                            forumUserSheet = true
                        } else {
                            forumLoginSheet = true
                        }
                    } label: {
                        AccountLabel(loggedIn: forumModel.isLogged, title: "FDU Hole Account")
                    }
                }
                
                CampusSettingsView()
                
                if forumModel.isLogged {
                    THSettingsView()
                }
                
                Section {
                    DetailLink(value: SettingsSection.about) {
                        Label("About", systemImage: "info.circle")
                            .navigationStyle()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onReceive(AppEvents.ScrollToTop.settings) { _ in
                withAnimation {
                    proxy.scrollTo("settings-top")
                }
            }
            .onReceive(AppEvents.notification) { content in
                navigator.pushDetail(value: ForumSettingsSection.notification, replace: true)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $forumLoginSheet) {
            DXAuthSheet()
        }
        .sheet(isPresented: $forumUserSheet) {
            DXUserSheet()
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

fileprivate struct DXUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                List {
                    AsyncContentView(style: .widget, animation: .default) { (forceReload: Bool) -> DXUser? in
                        if !forceReload {
                            if let user = DXModel.shared.user {
                                return user
                            }
                        }
                        // return nil when error
                        // this is to allow user to logout even when some error occurs and cannot connect to backend server
                        return try? await DXModel.shared.loadUser()
                    } content: { user in
                        if let user = user {
                            Section {
                                LabeledContent {
                                    Text(String(user.id))
                                } label: {
                                    Label("User ID", systemImage: "person.text.rectangle")
                                }
                                
                                LabeledContent {
                                    Text(user.joinTime.formatted(date: .long, time: .omitted))
                                } label: {
                                    Label("Join Date", systemImage: "calendar.badge.clock")
                                }
                                
                                if user.isAdmin {
                                    LabeledContent {
                                        Text("Enabled")
                                    } label: {
                                        Label("Admin Privilege", systemImage: "person.badge.key.fill")
                                    }
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            DXModel.shared.logout()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Logout")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .navigationTitle("Account Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

fileprivate struct AccountLabel: View {
    let loggedIn: Bool
    let title: LocalizedStringKey
    
    var body: some View {
        HStack {
            Image(systemName: loggedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.fill")
                .font(.system(size: 42))
                .symbolRenderingMode(.palette)
                .foregroundStyle(loggedIn ? Color.accentColor : Color.secondary,
                                 loggedIn ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.3))
                .padding(.horizontal)
                .padding(.vertical, 8)
            VStack(alignment: .leading, spacing: 3.0) {
                Text(title)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                Text(loggedIn ? "Logged in" : "Not Logged in")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}
