import SwiftUI

struct FDLoginSheet: View {
    @ObservedObject private var model = FDModel.shared
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        Sheet {
            try await FDModel.shared.login(username, password)
        } content: {
            FormTitle(title: "Fudan Campus Account", description: "Login with Fudan campus account (UIS) to access various campus services")
            
            Section {
                LabeledEntry("Student Type") {
                    Picker("", selection: $model.studentType) {
                        Text("Undergraduate").tag(FDStudentType.undergrad)
                        Text("Graduate").tag(FDStudentType.grad)
                        Text("Staff").tag(FDStudentType.staff)
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
    }
}

#Preview {
    FDLoginSheet()
}
