import SwiftUI

struct ContentView: View {
    @State private var showLoginSheet = false
    
    var body: some View {
        FDHomePage()
            .onAppear {
//                if !FDModel.shared.isLogged {
//                    showLoginSheet = true
//                }
                test()
            }
            .sheet(isPresented: $showLoginSheet) {
                FDLoginSheet()
            }
    }
}

#Preview {
    ContentView()
}
