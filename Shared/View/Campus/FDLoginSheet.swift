import SwiftUI

struct FDLoginSheet: View {
    @State var username = ""
    @State var password = ""
    
    var body: some View {
        Sheet("Fudan UIS Login") {
            try await FDModel.shared.login(username, password)
        } content: {
            TextField("Fudan UIS Account", text: $username)
                .keyboardType(.decimalPad)
            SecureField("Password", text: $password)
        }
        .completed(!username.isEmpty && !password.isEmpty)
        .submitText("Login")
    }
}

struct FDLoginSheet_Previews: PreviewProvider {
    static var previews: some View {
        FDLoginSheet()
    }
}
