import SwiftUI

struct HoleView: View {
    let hole: THHole
    
    var body: some View {
        VStack(alignment: .leading) {
            TagListSimple(tags: hole.tags)
            
            Text(hole.firstFloor.content.stripTreeholeSyntax())
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .transition(.slide)
            HStack {
                info
            }
        }
    }
    
    private var info: some View {
        HStack {
            Text("#\(String(hole.id))")
            Spacer()
            Text(hole.updateTime.formatted(date: .abbreviated, time: .shortened))
            Spacer()
            actions
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .foregroundColor(Color(uiColor: .systemGray2))
        .padding(.top, 3)
    }
    
    private var actions: some View {
        HStack(alignment: .center, spacing: 15) {
            HStack(alignment: .center, spacing: 3) {
                Image(systemName: "eye")
                Text(String(hole.view))
            }
            
            HStack(alignment: .center, spacing: 3) {
                Image(systemName: "ellipsis.bubble")
                Text(String(hole.reply))
            }
            
            // TODO: maybe add menu?
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
}

struct HoleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HoleView(hole: PreviewDecode.decodeObj(name: "hole")!)
            HoleView(hole: PreviewDecode.decodeObj(name: "hole")!)
                .preferredColorScheme(.dark)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
