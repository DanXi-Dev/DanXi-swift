import SwiftUI

struct SettingsPage: View {
    @ObservedObject private var forumModel = DXModel.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section("Accounts Management") {
                    FDAccountButton()
                    DXAccountButton()
                }
                
                if forumModel.isLogged {
                    THSettingsView()
                }
                
                Section {
                    NavigationLink {
                        AboutPage()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

fileprivate struct FDAccountButton: View {
    @ObservedObject private var model = FDModel.shared
    @State private var showLoginSheet = false
    @State private var showLogoutDialogue = false
    
    var body: some View {
        Button {
            if model.isLogged {
                showLogoutDialogue = true
            } else {
                showLoginSheet = true
            }
        } label: {
            AccountLabel(loggedIn: model.isLogged, title: "Fudan Campus Account")
        }
        .sheet(isPresented: $showLoginSheet) {
            FDLoginSheet()
        }
        .confirmationDialog("Accounts", isPresented: $showLogoutDialogue) {
            Button("Logout", role: .destructive) {
                model.logout()
            }
        }
    }
}

fileprivate struct DXAccountButton: View {
    @ObservedObject private var model = DXModel.shared
    @State private var showLoginSheet = false
    @State private var showUserSheet = false
    
    var body: some View {
        Button {
            if model.isLogged {
                showUserSheet = true
            } else {
                showLoginSheet = true
            }
        } label: {
            AccountLabel(loggedIn: model.isLogged, title: "FDU Hole Account")
        }
        .sheet(isPresented: $showLoginSheet) {
            DXAuthSheet()
        }
        .sheet(isPresented: $showUserSheet) {
            AsyncContentView { () -> DXUser? in
                if let user = model.user {
                    return user
                }
                // return nil when error
                // this is to allow user to logout even when some error occurs and cannot connect to backend server
                return try? await model.loadUser()
            } content: { user in
                DXUserSheet(user: user)
            }
        }
    }
}

fileprivate struct DXUserSheet: View {
    let user: DXUser?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if let user = user {
                    Section {
                        LabeledContent {
                            Text(String(user.id))
                        } label: {
                            Label("User ID", systemImage: "person.text.rectangle")
                        }
                        
                        if user.isAdmin {
                            LabeledContent {
                                Text("Enabled")
                            } label: {
                                Label("Admin Privilege", systemImage: "person.badge.key.fill")
                            }
                        }
                        
                        LabeledContent {
                            Text(user.nickname)
                        } label: {
                            Label("Nickname", systemImage: "person.crop.circle")
                        }
                        
                        LabeledContent {
                            Text(user.joinTime.formatted(date: .long, time: .omitted))
                        } label: {
                            Label("Join Date", systemImage: "calendar.badge.clock")
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
            Image(systemName: loggedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.fill.badge.plus")
                .font(.system(size: 42))
                .symbolRenderingMode(.palette)
                .foregroundStyle(loggedIn ? Color.accentColor : Color.secondary,
                                 loggedIn ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.3))
                .padding()
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
