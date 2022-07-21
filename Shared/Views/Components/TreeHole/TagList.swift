import SwiftUI

struct TagList: View {
    let color = Color.pink
    let tags: [THTag]
    
    var body: some View {
        FlexibleView(data: tags, spacing: 5.0, alignment: .leading) { tag in
            Text(tag.name)
                .padding(EdgeInsets(top: 2,leading: 6,bottom: 2,trailing: 6))
                .background(background)
                .foregroundColor(color)
                .font(.system(size: 14))
                .lineLimit(1)
        }
        
    }
    
    private var background: some View {
        let rectangle = RoundedRectangle(cornerRadius: 24, style: .circular)
        
        return rectangle
            .stroke(color)
            .background(rectangle.fill(color.opacity(0.05)))
    }
}

struct TagList_Previews: PreviewProvider {
    static let tag = THTag(id: 1, temperature: 1, name: "Tag")
    
    static let shortList = Array(repeating: tag, count: 2)
    
    static let longList = Array(repeating: tag, count: 15)
    
    static var previews: some View {
        Group {
            TagList(tags: shortList)
            TagList(tags: longList)
            TagList(tags: longList)
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
