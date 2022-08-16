import SwiftUI

struct SettingsPage: View {
    @ObservedObject var model = TreeholeDataModel.shared
    
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
                Toggle("NL Model Debugging Mode", isOn: $model.nlModelDebuggingMode)
            }
            
            Section("About") {
                Text("Legal")
                Text("About")
            }
        }
        .navigationTitle("settings")
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
            LoginPage()
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
