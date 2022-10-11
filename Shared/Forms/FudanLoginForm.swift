import SwiftUI

struct FudanLoginForm: View {
    @State var username = ""
    @State var password = ""
    
    var body: some View {
        FormPrimitive(title: "Fudan UIS Login",
                      submitText: "Login",
                      allowSubmit: !username.isEmpty && !password.isEmpty,
                      errorTitle: "Login Failed") {
            TextField("Fudan UIS Account", text: $username)
                .keyboardType(.decimalPad)
            SecureField("Password", text: $password)
        } action: {
            try await FDNetworks.shared.login(username, password)
        }
    }
}

struct FudanLoginForm_Previews: PreviewProvider {
    static var previews: some View {
        FudanLoginForm()
    }
}
