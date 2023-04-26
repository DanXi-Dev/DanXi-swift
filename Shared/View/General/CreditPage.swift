import SwiftUI

struct CreditPage: View {
    let licenses: [License] = Bundle.main.decodeData("license")
    let contributors: [Contributor] = Bundle.main.decodeData("contributor")

    var body: some View {
        List {
            Section("Contributors") {
                ForEach(contributors, id: \.name) { contributor in
                    HStack {
                        Image(contributor.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                            .overlay {
                                Circle().stroke(.white, lineWidth: 2)
                            }
                            .shadow(radius: 1)
                            .frame(width: 40)
                        Text(contributor.name)
                    }
                }
            }
            
            Section("Open Source Software") {
                ForEach(licenses, id: \.name) { license in
                    Link(destination: URL(string: license.link)!) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(license.name)
                                Text(license.license)
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Acknowledgements")
    }
}

fileprivate struct LinkView: View {
    let url: String
    let text: LocalizedStringKey
    let icon: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Label {
                    Text(text)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: icon)
                }
                Spacer()
                Image(systemName: "link")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct Contributor: Codable {
    let name: String
    let image: String
    let link: String
}

struct License: Codable {
    let name: String
    let link: String
    let license: String
}

struct CreditPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreditPage()
        }
    }
}
