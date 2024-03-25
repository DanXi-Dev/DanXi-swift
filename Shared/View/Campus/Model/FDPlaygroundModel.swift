import Foundation
import FudanKit

@MainActor
class FDPlaygroundModel: ObservableObject {    
    init(_ playgrounds: [Playground]) {
        self.playgrounds = playgrounds

        let categoriesSet = Set(playgrounds.map(\.category))
        self.categoriesList = Array(categoriesSet).sorted().reversed()

        let campusSet = Set(playgrounds.map(\.campus))
        self.campusList = Array(campusSet).sorted().reversed()
    }
    
    let categoriesList: [String]
    let campusList: [String]
    let playgrounds: [Playground]
    
    @Published var category = ""
    @Published var campus = ""

    var filteredPlaygrounds: [Playground] {
        var result = playgrounds
        if !campus.isEmpty {
            result = result.filter { $0.campus.contains(campus) }
        }
        if !category.isEmpty {
            result = result.filter { $0.category.contains(category) }
        }
        return result
    }
    
    func categoryIcon(_ category: String) -> String {
        let iconMap = ["钢琴": "pianokeys",
                       "琴房": "pianokeys",
                       "桌球": "circle.fill",
                       "活动中心": "building",
                       "篮球": "basketball.fill",
                       "羽毛球": "figure.badminton",
                       "足球": "soccerball",
                       "排球": "volleyball.fill",
                       "网球": "tennis.racket",
                       "舞蹈房": "figure.dance",
                       "体能房": "dumbbell.fill"]
        for (name, icon) in iconMap {
            if category.contains(name) {
                return icon
            }
        }
        return "circle.fill"
    }
}
