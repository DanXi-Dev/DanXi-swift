import SwiftUI

struct SettingsPage: View {
    @ObservedObject var model = TreeholeDataModel.shared
    @ObservedObject var preference = Preference.shared
    
    @State var showTreeHoleLogin = false
    @State var showTreeHoleActions = false
    
    var body: some View {
        List {
            Section("Accounts Management") {
                uisAccount
                if model.loggedIn {
                    treeHoleAccount
                } else {
                    treeHoleAccountNotLogged
                }
            }
            
            Section("Tree Hole") {
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
            
            Section("About") {
                Text("Legal")
                Text("About")
            }
        }
        .navigationTitle("Settings")
    }
    
    private var uisAccount: some View {
        HStack {
            Button(action: {  }) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 42))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.accentColor, Color.accentColor.opacity(0.3))
            }.padding()
            VStack(alignment: .leading, spacing: 3.0) {
                Text("Fudan UIS Account")
                    .fontWeight(.semibold)
                Text("Logged in")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var treeHoleAccount: some View {
        HStack {
            Button(action: {
                showTreeHoleActions = true
            }) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 42))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.accentColor, Color.accentColor.opacity(0.3))
            }.padding()
            VStack(alignment: .leading, spacing: 3.0) {
                Text("FDU Hole Account")
                    .fontWeight(.semibold)
                Text("Logged in")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .confirmationDialog("Accounts", isPresented: $showTreeHoleActions) {
            Button("Logout", role: .destructive) {
                withAnimation {
                    model.loggedIn = false
                    NetworkRequests.shared.logout()
                }
            }
        }
    }
    
    private var treeHoleAccountNotLogged: some View {
        HStack {
            Button(action: { showTreeHoleLogin = true }) {
                Image(systemName: "person.crop.circle.fill.badge.plus")
                    .font(.system(size: 42))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.secondary, Color.secondary.opacity(0.3))
            }.padding()
            VStack(alignment: .leading, spacing: 3.0) {
                Text("FDU Hole Account")
                    .fontWeight(.semibold)
                Text("Not Logged in")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showTreeHoleLogin) {
            LoginForm()
        }
    }
}

struct SettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsPage()
        }
    }
}
