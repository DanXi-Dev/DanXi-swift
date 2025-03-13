
import SwiftUI

struct Contributor {
    let name: String
    let image: Image
}

struct License {
    let name: String
    let link: URL
    let license: String
}

struct CreditPage: View {
    let licenses: [License] = [
        License(
            name: "SwiftSoup",
            link: URL(string: "https://github.com/scinfu/SwiftSoup")!,
            license: "MIT license"
        ),
        License(
            name: "Disk",
            link: URL(string: "https://github.com/saoudrizwan/Disk")!,
            license: "MIT license"
        ),
        License(
            name: "KeychainAccess",
            link: URL(string: "https://github.com/kishikawakatsumi/KeychainAccess")!,
            license: "MIT license"
        ),
        License(
            name: "SwiftUIX",
            link: URL(string: "https://github.com/SwiftUIX/SwiftUIX")!,
            license: "MIT license"
        ),
        License(
            name: "SwiftyJSON",
            link: URL(string: "https://github.com/SwiftyJSON/SwiftyJSON")!,
            license: "MIT license"
        ),
        License(
            name: "WrappingHStack",
            link: URL(string: "https://github.com/dkk/WrappingHStack")!,
            license: "MIT license"
        ),
        License(
            name: "BetterSafariView",
            link: URL(string: "https://github.com/stleamist/BetterSafariView/tree/v2.4.2")!,
            license: "MIT license"
        ),
        License(
            name: "SwiftUI Introspect",
            link: URL(string: "https://github.com/siteline/SwiftUI-Introspect")!,
            license: "Copyright 2019 Timber Software"
        ),
        License(
            name: "Queue",
            link: URL(string: "https://github.com/mattmassicotte/Queue")!,
            license: "BSD-3-Clause license"
        ),
        License(
            name: "IQKeyboardManager",
            link: URL(string: "https://github.com/hackiftekhar/IQKeyboardManager")!,
            license: "MIT license"
        )
    ]
let contributors: [Contributor] = [
        Contributor(
            name: "Boreas618",
            image:Image("Boreas618")
        ),
        Contributor(
            name: "Dest1n1",
            image:Image("Dest1n1")
        ),
        Contributor(
            name: "Frankstein73",
            image:Image("Frankstein73")
        ),
        Contributor(
            name: "fsy2001",
            image:Image("fsy2001")
        ),
        Contributor(
            name: "hasbai",
            image:Image( "hasbai")
        ),
        Contributor(
            name: "ivanfei",
            image:Image("ivanfei")
        ),
        Contributor(
            name: "JingYiJun",
            image:Image( "JingYiJun")
        ),
        Contributor(
            name: "kyln24",
            image:Image("kyln24")
        ),
        Contributor(
            name: "Linn3a",
            image:Image("Linn3a")
        ),
        Contributor(
            name: "PinappleUnderTheSea",
           image:Image("PinappleUnderTheSea")
        ),
        Contributor(
            name: "ppolariss",
            image:Image("ppolariss")
        ),
        Contributor(
            name: "ryanhe312",
            image:Image("ryanhe312")
        ),
        Contributor(
            name: "Serenii02",
            image:Image("Serenii02")
        ),
        Contributor(
            name: "singularity-s0",
            image:Image("singularity-s0")
        ),
        Contributor(
            name: "yujular",
            image:Image("yujular")
        ),
        Contributor(
            name: "w568w",
            image:Image("w568w")
        )
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(contributors.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }), id: \.name) { contributor in
                    HStack {
                        contributor.image
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
            } header: {
                Text("Contributors")
            } footer: {
                Text("Sort alphabetically.")
            }

            Section("Open Source Software") {
                ForEach(licenses.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }), id: \.name) { license in
                    Link(destination: license.link) {
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

struct LinkView: View {
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

struct CreditPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreditPage()
        }
    }
}
