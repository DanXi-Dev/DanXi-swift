import SwiftUI

struct DebugPage: View {
    @State private var auth: String = FDUHOLE_AUTH_URL
    @State private var fduhole: String = FDUHOLE_BASE_URL
    @State private var danke: String = DANKE_BASE_URL
    
    var body: some View {
        Form {
            Section {
                TextField("Auth", text: $auth)
                TextField("fduhole", text: $fduhole)
                TextField("danke", text: $danke)
            }
            
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if let authURL = URL(string: auth),
                       let fduholeURL = URL(string: fduhole),
                       let dankeURL = URL(string: danke) {
                        FDUHOLE_AUTH_URL = authURL.absoluteString
                        FDUHOLE_BASE_URL = fduholeURL.absoluteString
                        DANKE_BASE_URL = dankeURL.absoluteString
                    }
                } label: {
                    Text("Submit")
                }
            }
        }
        .navigationTitle("Debug")
    }
}

#Preview {
    NavigationStack {
        DebugPage()
    }
}
