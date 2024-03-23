import SwiftUI

struct SettingsPage: View {
    @ObservedObject private var forumModel = DXModel.shared
    @ObservedObject private var campusModel = FDModel.shared
    
    @State private var campusLoginSheet = false
    @State private var campusUserSheet = false
    @State private var forumLoginSheet = false
    @State private var forumUserSheet = false
    
    var showToolbar: Bool {
        campusModel.isLogged || forumModel.isLogged
    }
    
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
                
                if campusModel.isLogged {
                    Section("Campus.Tab") {
                        Picker(selection: $campusModel.studentType) {
                            Text("Undergraduate").tag(FDStudentType.undergrad)
                            Text("Graduate").tag(FDStudentType.grad)
                            Text("Staff").tag(FDStudentType.staff)
                        } label: {
                            Text("Student Type")
                        }
                    }
                }
                
                if forumModel.isLogged {
                    THSettingsView()
                }
                
                Section {
                    NavigationLink {
                        AboutPage()
                    } label: {
                        Text("About")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $campusLoginSheet) {
            FDLoginSheet()
        }
        .sheet(isPresented: $campusUserSheet) {
            FDUserSheet()
        }
        .sheet(isPresented: $forumLoginSheet) {
            DXAuthSheet()
        }
        .sheet(isPresented: $forumUserSheet) {
            DXUserSheet()
        }
        .toolbar(showToolbar ? .visible : .hidden, for: .tabBar)
    }
}

fileprivate struct FDUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                List {
                    AsyncContentView(style: .widget, animation: .default) { () -> FDIdentity? in
                        return try? await FDIdentityAPI.getIdentity()
                    } content: { identity in
                        if let identity = identity {
                            Section {
                                LabeledContent("Name", value: identity.name)
                                LabeledContent("Fudan.ID", value: identity.studentId)
                                LabeledContent("ID Number", value: identity.idNumber)
                                LabeledContent("Department", value: identity.department)
                                LabeledContent("Major", value: identity.major)
                            }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }
}

fileprivate struct DXUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                List {
                    AsyncContentView(style: .widget, animation: .default) { () -> DXUser? in
                        if let user = DXModel.shared.user {
                            return user
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
                                    Text(user.nickname)
                                } label: {
                                    Label("Nickname", systemImage: "person.crop.circle")
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
