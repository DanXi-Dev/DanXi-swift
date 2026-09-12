import SwiftUI
import FudanKit
import ViewUtils

public struct LoginSheet: View {
    private let style: SheetStyle
    @ObservedObject private var model = CampusModel.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var failedAttempts = 0
    
    public init(style: SheetStyle = .independent) {
        self.style = style
    }
    
    public var body: some View {
        Sheet {
            do {
                try await model.login(username: username, password: password)
            }
            catch {
                failedAttempts += 1
                throw error
            }
        } content: {
            #if os(watchOS)
            
            Picker(selection: $model.studentType) {
                Text("Undergraduate", bundle: .module).tag(StudentType.undergrad)
                Text("Graduate", bundle: .module).tag(StudentType.grad)
                Text("Staff", bundle: .module).tag(StudentType.staff)
            } label: {
                Text("Student Type", bundle: .module)
            }
            
            TextField(String(localized: "Fudan.ID", bundle: .module), text: $username)

            SecureField(String(localized: "Password", bundle: .module), text: $password)
            
            #else
            
            FormTitle(title: String(localized: "Fudan Campus Account", bundle: .module), description: String(localized: "Login with Fudan campus account to access various campus services", bundle: .module))
            
            Section {
                LabeledEntry(String(localized: "Student Type", bundle: .module)) {
                    Picker(String(""), selection: $model.studentType) {
                        Text("Undergraduate", bundle: .module).tag(StudentType.undergrad)
                        Text("Graduate", bundle: .module).tag(StudentType.grad)
                        Text("Staff", bundle: .module).tag(StudentType.staff)
                    }
                }
                LabeledEntry(String(localized: "Fudan.ID", bundle: .module)) {
                    TextField(String(localized: "Fudan.ID", bundle: .module), text: $username)
                }
                LabeledEntry(String(localized: "Password", bundle: .module)) {
                    SecureField(String(localized: "Password", bundle: .module), text: $password)
                }
            }
            
            #endif
            
            if failedAttempts >= 3 && !username.isEmpty && !password.isEmpty {
                Section {
                    Button {
                        model.forceLogin(username: username, password: password)
                        dismiss()
                    } label: {
                        Text("Ignore check and login", bundle: .module)
                    }
                } footer: {
                    Text("If credential validation is unavailable, you can continue without checking. Some campus services may remain unavailable.", bundle: .module)
                }
            }
        }
        .completed(!username.isEmpty && !password.isEmpty)
        .submitText(String(localized: "Login", bundle: .module))
        .sheetStyle(style)
    }
}

#Preview {
    List {
        
    }
    .sheet(isPresented: .constant(true)) {
        LoginSheet()
    }
}
