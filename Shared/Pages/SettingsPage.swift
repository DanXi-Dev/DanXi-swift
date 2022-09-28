import SwiftUI

struct SettingsPage: View {
    @ObservedObject var model = TreeholeDataModel.shared
    @ObservedObject var preference = Preference.shared
    
    @State var showTreeHoleLogin = false
    @State var showTreeHoleActions = false
    
    init() { }
    
    /// Init for preview.
    init(user: DXUser) {
        model.user = user
        model.loggedIn = true
    }
    
    var body: some View {
        List {
            Section("Accounts Management") {
                uisAccount
                danxiAccount
            }
            
            if model.loggedIn {
                treeholeSettings
            }
            
            Section("About") {
                Text("Legal")
                Text("About")
            }
        }
        .navigationTitle("Settings")
    }
    
    // MARK: Accounts
    
    @ViewBuilder
    private var uisAccount: some View {
        Button(action: {  }) {
            HStack {
                accountIcon(loggedIn: true)
                    .padding()
                accountText(title: "Fudan UIS Account", description: "Logged in")
            }
        }
    }
    
    @ViewBuilder
    private var danxiAccount: some View {
        if model.loggedIn {
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
                        model.logout()
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
                LoginForm()
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
                danxiUserInfo
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
                    TagField(tags: $preference.blockedTags)
                }
                .navigationTitle("Blocked Tags")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("Blocked Tags", systemImage: "tag.slash")
            }
        }
    }

    private var danxiUserInfo: some View {
        List {
            if let user = model.user {
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
        .navigationTitle("Account Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsPage(user: PreviewDecode.decodeObj(name: "user")!)
        }
    }
}
