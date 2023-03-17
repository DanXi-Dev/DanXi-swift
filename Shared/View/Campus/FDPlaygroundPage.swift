import SwiftUI

struct FDPlaygroundPage: View {
    @State var playgrounds: [FDPlayground] = []
    var types: [String] {
        return Array(Set(playgrounds.map(\.type)))
    }
    var campusList: [String] {
        return Array(Set(playgrounds.map(\.campus)))
    }
    
    @State var campusSelection = ""
    @State var typeSelection = ""
    var filteredPlaygrounds: [FDPlayground] {
        var result = playgrounds
        if !campusSelection.isEmpty {
            result = result.filter { $0.campus.contains(campusSelection) }
        }
        if !typeSelection.isEmpty {
            result = result.filter { $0.type.contains(typeSelection) }
        }
        return result
    }
    
    func initialLoad() async throws {
        try await FDPlaygroundAPI.login()
        let categories = try await FDPlaygroundAPI.getCategories()
        playgrounds.append(contentsOf: try await FDPlaygroundAPI.getPlaygroundList(category: categories[0]))
        playgrounds.append(contentsOf: try await FDPlaygroundAPI.getPlaygroundList(category: categories[2]))
    }
    
    func categoryIcon(_ category: String) -> String {
        let iconMap = ["钢琴": "pianokeys",
                       "琴房": "pianokeys",
                       "桌球": "circle.fill",
                       "活动中心": "person.3.sequence.fill",
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
    
    var body: some View {
        LoadingPage(action: initialLoad) {
            List {
                Section {
                    Picker(selection: $campusSelection, label: Text("Campus")) {
                        ForEach(campusList, id: \.self) { campus in
                            Text(campus).tag(campus)
                        }
                        Text("All").tag("")
                    }
                    Picker(selection: $typeSelection, label: Text("Playground Type")) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                        Text("All").tag("")
                    }
                }
                
                Section("Playground List") {
                    ForEach(filteredPlaygrounds) { playground in
                        NavigationLink {
                            Text("TODO")
                        } label: {
                            Label(playground.name, systemImage: categoryIcon(playground.type))
                        }
                    }
                }
            }
            .navigationTitle("Playground Reservation")
        }
    }
}

struct FDPlaygroundPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FDPlaygroundPage()
        }
    }
}
