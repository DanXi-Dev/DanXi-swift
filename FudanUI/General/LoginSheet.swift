import SwiftUI
import FudanKit
import ViewUtils

public struct LoginSheet: View {
    private let style: SheetStyle
    @ObservedObject private var model = CampusModel.shared
    @State private var username = ""
    @State private var password = ""
    @State private var captcha = ""
    @ObservedObject var loginForm = AuthenticationForm.shared
    
    public init(style: SheetStyle = .independent) {
        self.style = style
    }
    
    public var body: some View {
        AsyncContentView {
            try await model.retrieveAuthenticationForm()
        } content: {
            Sheet {
                let authContent = AuthenticationContent(username: username, password: password, captcha: captcha.count != 0 ? captcha : nil, additional: loginForm.additional)
                try await model.submitAuthenticationForm(content: authContent)
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
                    if loginForm.captcha != nil {
                        LabeledEntry(String(localized: "Captcha", bundle: .module)) {
                            SecureField(String(localized: "Fudan UIS Captcha", bundle: .module), text: $captcha)
                        }
                        HStack{
                            Spacer()
                            loginForm.captcha?.resizable()
                                .scaledToFit()
                            Spacer()
                            
                        }
                    }
                }
                #endif
            }
            .completed(!username.isEmpty && !password.isEmpty)
            .submitText(String(localized: "Login", bundle: .module))
            .sheetStyle(style)
        }
        
    }
}

#Preview {
    List {
        
    }
    .sheet(isPresented: .constant(true)) {
        LoginSheet()
    }
}
