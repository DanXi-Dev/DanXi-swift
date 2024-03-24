import SwiftUI
import FudanKit

struct FDLoginSheet: View {
    let style: SheetStyle
    @ObservedObject private var model = CampusModel.shared
    @State private var username = ""
    @State private var password = ""
    
    init(style: SheetStyle = .independent) {
        self.style = style
    }
    
    var body: some View {
        Sheet {
            try await model.login(username: username, password: password)
        } content: {
            FormTitle(title: "Fudan Campus Account", description: "Login with Fudan campus account (UIS) to access various campus services")
            
            Section {
                LabeledEntry("Student Type") {
                    Picker("", selection: $model.studentType) {
                        Text("Undergraduate").tag(StudentType.undergrad)
                        Text("Graduate").tag(StudentType.grad)
                        Text("Staff").tag(StudentType.staff)
                    }
                }
                LabeledEntry("Fudan.ID") {
                    TextField("Required", text: $username)
                }
                LabeledEntry("Password") {
                    SecureField("Required", text: $password)
                }
            }
        }
        .completed(!username.isEmpty && !password.isEmpty)
        .submitText("Login")
        .sheetStyle(style)
    }
}

#Preview {
    FDLoginSheet()
}
