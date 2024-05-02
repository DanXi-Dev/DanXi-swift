import SwiftUI

struct StructuredWatermarkView: View {
    let content: String?
    let rowCount: Int
    let columnCount: Int
    let opacity: Double?
    
    @ObservedObject var profileStore = ProfileStore.shared
    @ObservedObject var settings = ForumSettings.shared
    
    var userId: String {
        if let id = profileStore.profile?.id {
            String(id)
        } else {
            ""
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(columnCount)
            let cellHeight = geometry.size.height / CGFloat(rowCount)
            
            ForEach(0..<rowCount * columnCount, id: \.self) { index in
                let row = index / columnCount
                let column = index % columnCount
                
                Text(content ?? userId)
                    .font(.system(size: 30))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.primary.opacity(opacity ?? settings.watermarkOpacity))
                    .rotationEffect(.degrees(20))
                    .frame(width: cellWidth, height: cellHeight, alignment: .center)
                    .position(x: CGFloat(column) * cellWidth + cellWidth / 2,
                              y: CGFloat(row) * cellHeight + cellHeight / 2)
            }
        }
        .background(Color.clear)
    }
}

struct WatermarkModifier: ViewModifier {
    let watermarkContent: String?
    let opacity: Double?
    
    init() {
        self.watermarkContent = nil
        self.opacity = nil
    }
    
    init(watermarkContent: String?, opacity: Double?) {
        self.watermarkContent = watermarkContent
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                StructuredWatermarkView(content: watermarkContent, rowCount: 10, columnCount: 4, opacity: opacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )
    }
}

extension View {
    func watermark() -> some View {
        self.modifier(WatermarkModifier())
    }
    
    func watermark(content: String, opacity: Double) -> some View {
        self.modifier(WatermarkModifier(watermarkContent: content, opacity: opacity))
    }
}
