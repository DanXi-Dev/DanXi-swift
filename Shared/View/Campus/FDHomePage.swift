import SwiftUI

struct FDHomePage: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    FDPayPage()
                } label: {
                    Label("Fudan QR Code", systemImage: "qrcode")
                }
                
                NavigationLink {
                    FDSportPage()
                } label: {
                    Label("PE Curriculum", systemImage: "figure.disc.sports")
                }

                NavigationLink {
                    FDBusPage()
                } label: {
                    Label("Bus Schedule", systemImage: "bus.fill")
                }
                
                NavigationLink {
                    FDEcardPage()
                } label: {
                    Label("ECard Information", systemImage: "creditcard")
                }
                
                NavigationLink {
                    FDScorePage()
                } label: {
                    Label("Exams & Score", systemImage: "graduationcap")
                }
            }
            .navigationTitle("Campus Services")
        }
    }
}

struct FDHomePage_Previews: PreviewProvider {
    static var previews: some View {
        FDHomePage()
    }
}
