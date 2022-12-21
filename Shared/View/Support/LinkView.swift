import SwiftUI

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

struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LinkView(url: "https://canvas.fduhole.com", text: "Canvas", icon: "paintbrush.pointed")
        }
    }
}
