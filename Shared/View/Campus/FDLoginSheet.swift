import SwiftUI

struct FDLoginSheet: View {
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
            try await FDModel.shared.login(username, password)
        }
    }
}

struct FDLoginSheet_Previews: PreviewProvider {
    static var previews: some View {
        FDLoginSheet()
    }
}
