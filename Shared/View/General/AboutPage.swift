import SwiftUI

struct AboutPage: View {
    var body: some View {
        List {
            Section {
                LinkView(url: "https://danxi.fduhole.com", text: "Website", icon: "safari")
                LinkView(url: "https://danxi.fduhole.com/doc/app-terms-and-condition", text: "Terms and Conditions", icon: "info.circle")

                NavigationLink {
                    CreditPage()
                } label: {
                    Label("Acknowledgements", systemImage: "heart")
                }
            } header: {
                appIcon
            }
        }
        .navigationTitle("About")
    }

    private var appIcon: some View {
        HStack {
            Spacer()
            VStack {
                Image("Icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                Text("DanXi")
                    .font(.title)
                    .bold()
                Text("Version \(Bundle.main.releaseVersionNumber!)")
                    .font(.callout)
            }
            .padding(.bottom)
            Spacer()
        }
    }
}
