import DanXiKit

enum HoleSegment: Identifiable {
    var id: Int {
        switch self {
        case let .floor(presentation):
            presentation.floor.id
        case let .folded(presentations):
            presentations.first?.floor.id ?? 0
        }
    }
    
    case floor(FloorPresentation)
    case folded([FloorPresentation])
}


