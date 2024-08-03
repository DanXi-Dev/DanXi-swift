import FudanKit
import SwiftUI
import ViewUtils

struct ReservationPage: View {
    var body: some View {
        AsyncContentView {
            let playgrounds = try await ReservationStore.shared.getCachedPlayground()
            return PlaygroundModel(playgrounds)
        } refreshAction: {
            let playgrounds = try await ReservationStore.shared.getRefreshedPlayground()
            return PlaygroundModel(playgrounds)
        } content: { model in
            PlaygroundContent(model)
        }
        .navigationTitle(String(localized: "Playground Reservation", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlaygroundContent: View {
    @StateObject private var model: PlaygroundModel
    
    init(_ model: PlaygroundModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        List {
            Section {
                Picker(selection: $model.campus, label: Text("Campus", bundle: .module)) {
                    Text("All", bundle: .module).tag("")
                    ForEach(model.campusList, id: \.self) { campus in
                        Text(campus).tag(campus)
                    }
                }
                Picker(selection: $model.category, label: Text("Playground Type", bundle: .module)) {
                    Text("All", bundle: .module).tag("")
                    ForEach(model.categoriesList, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
            }
            
            Section {
                ForEach(model.filteredPlaygrounds) { playground in
                    DetailLink(value: playground) {
                        Label(playground.name, systemImage: model.categoryIcon(playground.category))
                            .navigationStyle()
                    }
                }
            } header: {
                Text("Playground List", bundle: .module)
            }
        }
        .navigationDestination(for: Playground.self) { playground in
            PlaygroundPage(playground)
        }
    }
}

struct PlaygroundPage: View {
    private let playground: Playground
    @State private var showAvailable = false
    @State private var date = Date.now
    
    init(_ playground: Playground) {
        self.playground = playground
    }
    
    var body: some View {
        List {
            Section {
                DatePicker(String(localized: "Date", bundle: .module), selection: $date, displayedComponents: [.date])
                Toggle(String(localized: "Available Time Slots Only", bundle: .module), isOn: $showAvailable)
            }
            
            AsyncContentView(style: .widget) {
                try await ReservationStore.shared.getReservations(playground: playground, date: date)
            } content: { reservations in
                let filteredReservations = reservations.filter { $0.available || !showAvailable }
                
                if filteredReservations.isEmpty {
                    Text("No Time Slots Available", bundle: .module)
                } else {
                    Grid(alignment: .center) {
                        ForEach(filteredReservations) { reservation in
                            ReservationView(reservation: reservation)
                                .padding(.vertical, 2)
                            if reservation.id != filteredReservations.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .id(date)
        }
        .navigationTitle(playground.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct ReservationView: View {
    let reservation: Reservation
    @State private var showSheet = false
    
    var body: some View {
        GridRow {
            Group {
                Text(verbatim: "\(reservation.begin.formatted(date: .omitted, time: .shortened)) - \(reservation.end.formatted(date: .omitted, time: .shortened))")
                Text(verbatim: "\(reservation.reserved) / \(reservation.total)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if reservation.available {
                    Button {
                        showSheet = true
                    } label: {
                        Text("Reserve", bundle: .module)
                    }
                    .buttonStyle(.borderless)
                } else if reservation.reserved == reservation.total {
                    Text("Full", bundle: .module)
                        .foregroundColor(.secondary)
                } else {
                    Text("Unavailable", bundle: .module)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            ReservationSheet(reservation)
        }
    }
}

fileprivate struct ReservationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let reservation: Reservation
    let request: URLRequest?
    
    init(_ reservation: Reservation) {
        self.reservation = reservation
        if let url = reservation.reserveURL {
            self.request = URLRequest(url: url)
        } else {
            self.request = nil
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let request = request {
                    WebViewWrapper(request)
                } else {
                    Text("Cannot Reserve", bundle: .module)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
            .navigationTitle(String(localized: "Reserve Page", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

@MainActor
class PlaygroundModel: ObservableObject {
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
                       "体能房": "dumbbell.fill",
                       "乒乓球": "figure.table.tennis"]
        for (name, icon) in iconMap {
            if category.contains(name) {
                return icon
            }
        }
        return "circle.fill"
    }
}
