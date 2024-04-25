import SwiftUI
import FudanKit
import ViewUtils

public struct LoginSheet: View {
    private let style: SheetStyle
    @ObservedObject private var model = CampusModel.shared
    @State private var username = ""
    @State private var password = ""
    
    public init(style: SheetStyle = .independent) {
        self.style = style
    }
    
    public var body: some View {
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
                    TextField("Fudan UIS ID", text: $username)
                }
                LabeledEntry("Password") {
                    SecureField("Fudan UIS Password", text: $password)
                }
            }
        }
        .completed(!username.isEmpty && !password.isEmpty)
        .submitText("Login")
        .sheetStyle(style)
    }
}
