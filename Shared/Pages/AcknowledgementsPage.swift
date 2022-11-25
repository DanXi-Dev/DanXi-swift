import SwiftUI

struct AcknowledgementsPage: View {
    let licenses: [License] = Bundle.main.jsonData(name: "license")
    let contributors: [Contributor] = Bundle.main.jsonData(name: "contributor")

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
        .navigationBarTitleDisplayMode(.inline)
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

struct AcknowledgementsPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AcknowledgementsPage()
        }
    }
}