import Foundation

@MainActor
class FDPlaygroundModel: ObservableObject {
    static func load() async throws -> FDPlaygroundModel {
        try await FDPlaygroundAPI.login()
        let categories = try await FDPlaygroundAPI.getCategories()
        var playgrounds: [FDPlayground] = []
        playgrounds += try await FDPlaygroundAPI.getPlaygroundList(category: categories[0])
        playgrounds += try await FDPlaygroundAPI.getPlaygroundList(category: categories[2])
        return FDPlaygroundModel(playgrounds)
    }
    
    init(_ playgrounds: [FDPlayground]) {
        self.playgrounds = playgrounds
        self.typesList = Array(Set(playgrounds.map(\.type))).sorted().reversed()
        self.campusList = Array(Set(playgrounds.map(\.campus))).sorted().reversed()
    }
    
    let typesList: [String]
    let campusList: [String]
    let playgrounds: [FDPlayground]
    
    @Published var type = ""
    @Published var campus = ""
    var filteredPlaygrounds: [FDPlayground] {
        var result = playgrounds
        if !campus.isEmpty {
            result = result.filter { $0.campus.contains(campus) }
        }
        if !type.isEmpty {
            result = result.filter { $0.type.contains(type) }
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
