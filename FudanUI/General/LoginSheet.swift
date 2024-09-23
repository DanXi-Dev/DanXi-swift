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
            FormTitle(title: String(localized: "Fudan Campus Account", bundle: .module), description: String(localized: "Login with Fudan campus account (UIS) to access various campus services", bundle: .module))
            
            Section {
                LabeledEntry(String(localized: "Student Type", bundle: .module)) {
                    Picker(String(""), selection: $model.studentType) {
                        Text("Undergraduate", bundle: .module).tag(StudentType.undergrad)
                        Text("Graduate", bundle: .module).tag(StudentType.grad)
                        Text("Staff", bundle: .module).tag(StudentType.staff)
                    }
                }
                LabeledEntry(String(localized: "Fudan.ID", bundle: .module)) {
                    TextField(String(localized: "Fudan UIS ID", bundle: .module), text: $username)
                }
                LabeledEntry(String(localized: "Password", bundle: .module)) {
                    SecureField(String(localized: "Fudan UIS Password", bundle: .module), text: $password)
                }
            }
        }
        .completed(!username.isEmpty && !password.isEmpty)
        .submitText(String(localized: "Login", bundle: .module))
        .sheetStyle(style)
    }
}
