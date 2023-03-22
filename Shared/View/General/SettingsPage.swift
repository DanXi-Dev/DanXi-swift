import SwiftUI

struct SettingsPage: View {
    @ObservedObject var forumModel = DXModel.shared
    @ObservedObject var campusModel = FDModel.shared
    @ObservedObject var preference = Preference.shared
    
    @State var showTreeHoleLogin = false
    @State var showTreeHoleActions = false
    
    @State var showFudanLogin = false
    @State var showFudanActions = false
    
    init() { }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Accounts Management") {
                    uisAccount
                    danxiAccount
                }
                
                if forumModel.isLogged {
                    treeholeSettings
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
    
    // MARK: Accounts
    
    @ViewBuilder
    private var uisAccount: some View {
        if campusModel.isLogged {
            Button(action: {
                showFudanActions = true
            }) {
                HStack {
                    accountIcon(loggedIn: true)
                        .padding()
                    accountText(title: "Fudan UIS Account", description: "Logged in")
                }
            }
            .confirmationDialog("Accounts", isPresented: $showFudanActions) {
                Button("Logout", role: .destructive) {
                    withAnimation {
                        campusModel.logout()
                    }
                }
            }
        } else {
            Button {
                showFudanLogin = true
            } label: {
                HStack {
                    accountIcon(loggedIn: false)
                        .padding()
                    accountText(title: "Fudan UIS Account", description: "Not Logged in")
                }
            }
            .sheet(isPresented: $showFudanLogin) {
                FDLoginSheet()
            }
        }
    }
    
    @ViewBuilder
    private var danxiAccount: some View {
        if forumModel.isLogged {
            Button(action: {
                showTreeHoleActions = true
            }) {
                HStack {
                    accountIcon(loggedIn: true)
                        .padding()
                    accountText(title: "FDU Hole Account", description: "Logged in")
                }
            }
            .confirmationDialog("Accounts", isPresented: $showTreeHoleActions) {
                Button("Logout", role: .destructive) {
                    withAnimation {
                        forumModel.logout()
                    }
                }
            }
        } else {
            Button(action: { showTreeHoleLogin = true }) {
                HStack {
                    accountIcon(loggedIn: false)
                        .padding()
                    accountText(title: "FDU Hole Account", description: "Not Logged in")
                }
            }
            .sheet(isPresented: $showTreeHoleLogin) {
                DXLoginSheet()
            }
        }
    }
    
    @ViewBuilder
    private func accountIcon(loggedIn: Bool) -> some View {
        Image(systemName: loggedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.fill.badge.plus")
            .font(.system(size: 42))
            .symbolRenderingMode(.palette)
            .foregroundStyle(loggedIn ? Color.accentColor : Color.secondary,
                             loggedIn ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.3))
    }
    
    @ViewBuilder
    private func accountText(title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 3.0) {
            Text(title)
                .foregroundColor(.primary)
                .fontWeight(.semibold)
            Text(description)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: Treehole Settings
    
    private var treeholeSettings: some View {
        Section("Tree Hole") {
            NavigationLink {
                DXUserInfoPage()
            } label: {
                Label("Account Info", systemImage: "info.circle")
            }
            
            Picker(selection: $preference.nsfwSetting, label: Label("NSFW Content", systemImage: "eye.slash")) {
                Text("Show").tag(NSFWPreference.show)
                Text("Fold").tag(NSFWPreference.fold)
                Text("Hide").tag(NSFWPreference.hide)
            }
            
            Toggle(isOn: $preference.nlModelDebuggingMode) {
                Label("NL Model Debugging Mode", systemImage: "dice")
            }
            
            NavigationLink {
                Form {
                    THTagField(tags: $preference.blockedTags)
                }
                .navigationTitle("Blocked Tags")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("Blocked Tags", systemImage: "tag.slash")
            }
        }
    }
}

struct DXUserInfoPage: View {
    @State var user: DXUser? = DXModel.shared.user
    
    var body: some View {
        LoadingPage(finished: user == nil) {
            try await DXModel.shared.loadUser()
            self.user = DXModel.shared.user
        } content: {
            if let user = user {
                HStack {
                    Label("User ID", systemImage: "person.text.rectangle")
                    Spacer()
                    Text(String(user.id))
                        .foregroundColor(.secondary)
                }
                
                if user.isAdmin {
                    HStack {
                        Label("Admin Privilege", systemImage: "person.badge.key.fill")
                        Spacer()
                        Text("Enabled")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label("Nickname", systemImage: "person.crop.circle")
                    Spacer()
                    Text(user.nickname)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Join Date", systemImage: "calendar.badge.clock")
                    Spacer()
                    Text(user.joinTime.formatted(date: .long, time: .omitted))
                        .foregroundColor(.secondary)
                }
            }
        }

    }
}

struct SettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        SettingsPage()
    }
}
