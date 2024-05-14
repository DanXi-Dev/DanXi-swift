import Foundation
import DanXiKit

struct HolePresentation: Identifiable {
    var id: Int {
        hole.id
    }

    let hole: Hole
    let firstFloorContent: AttributedString
    let lastFloorContent: AttributedString?
    let sensitive: Bool
    let prefetch: [FloorPresentation]

    init(hole: Hole) {
        self.hole = hole
        let firstFloorContent = hole.firstFloor.fold.isEmpty ? hole.firstFloor.content : hole.firstFloor.fold
        self.firstFloorContent = firstFloorContent.inlineAttributed()
        self.lastFloorContent = if hole.firstFloor.id != hole.lastFloor.id {
            (hole.lastFloor.fold.isEmpty ? hole.lastFloor.content : hole.lastFloor.fold).inlineAttributed()
        } else {
            nil
        }
        self.sensitive = hole.tags.filter { $0.name.hasPrefix("*") }.count > 0
        self.prefetch = hole.prefetch.enumerated().map { FloorPresentation(floor: $1, storey: $0 + 1, floors: hole.prefetch)}
    }
}
