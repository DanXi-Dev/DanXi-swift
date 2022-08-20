import SwiftUI

struct MentionView: View {
    let poster: String
    let content: String
    let floorId: Int
    let date: Date
    
    init(floor: THFloor) {
        self.poster = floor.posterName
        self.content = floor.content
        self.floorId = floor.id
        self.date = floor.createTime
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .frame(width: 3, height: 15)
                
                Text(poster)
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "quote.closing")
                    .foregroundColor(.secondary)
            }
            .foregroundColor(randomColor(name: poster))
            
            Text(content)
                .font(.callout)
                .lineLimit(3)
            
            HStack {
                Text("#\(String(floorId))")
                Spacer()
                Text(date.formatted(.relative(presentation: .named, unitsStyle: .wide)))
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 1.0)
        }
        .padding(.horizontal)
        .padding(.vertical, 7.0)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(7.0)
    }
}

struct MentionView_Previews: PreviewProvider {
    static var previews: some View {
        MentionView(floor: PreviewDecode.decodeObj(name: "floor")!)
            .padding()
    }
}
