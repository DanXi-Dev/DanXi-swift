import SwiftUI

struct SettingsPage: View {
    @ObservedObject private var forumModel = DXModel.shared
    @ObservedObject private var campusModel = FDModel.shared
    
    @State private var campusLoginSheet = false
    @State private var campusUserSheet = false
    @State private var forumLoginSheet = false
    @State private var forumUserSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Accounts Management") {
                    Button {
                        if campusModel.isLogged {
                            campusUserSheet = true
                        } else {
                            campusLoginSheet = true
                        }
                    } label: {
                        AccountLabel(loggedIn: campusModel.isLogged, title: "Fudan Campus Account")
                    }
                    
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
        .sheet(isPresented: $campusLoginSheet) {
            FDLoginSheet()
        }
        .sheet(isPresented: $campusUserSheet) {
            AsyncContentView { () -> FDIdentity? in
                return try? await FDIdentityAPI.getIdentity()
            } content: { identity in
                FDUserSheet(identity: identity)
            }
        }
        .sheet(isPresented: $forumLoginSheet) {
            DXAuthSheet()
        }
        .sheet(isPresented: $forumUserSheet) {
            AsyncContentView { () -> DXUser? in
                if let user = forumModel.user {
                    return user
                }
                // return nil when error
                // this is to allow user to logout even when some error occurs and cannot connect to backend server
                return try? await forumModel.loadUser()
            } content: { user in
                DXUserSheet(user: user)
            }
        }
    }
}

fileprivate struct FDUserSheet: View {
    let identity: FDIdentity?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if let identity = identity {
                    Section {
                        LabeledContent("Name", value: identity.name)
                        LabeledContent("Fudan.ID", value: identity.studentId)
                        LabeledContent("ID Number", value: identity.idNumber)
                        LabeledContent("Department", value: identity.department)
                        LabeledContent("Major", value: identity.major)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        FDModel.shared.logout()
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
