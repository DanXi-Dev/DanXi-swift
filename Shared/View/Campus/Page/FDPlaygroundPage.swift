import SwiftUI
import FudanKit

struct FDPlaygroundPage: View {
    var body: some View {
        AsyncContentView {
            let playgrounds = try await ReservationStore.shared.getRefreshedPlayground()
            return FDPlaygroundModel(playgrounds)
        } content: { model in
            FDPlaygroundContent(model)
        }
    }
}

fileprivate struct FDPlaygroundContent: View {
    @StateObject private var model: FDPlaygroundModel
    
    init(_ model: FDPlaygroundModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        List {
            Section {
                Picker(selection: $model.campus, label: Text("Campus")) {
                    Text("All").tag("")
                    ForEach(model.campusList, id: \.self) { campus in
                        Text(campus).tag(campus)
                    }
                }
                Picker(selection: $model.category, label: Text("Playground Type")) {
                    Text("All").tag("")
                    ForEach(model.categoriesList, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
            }
            
            Section("Playground List") {
                ForEach(model.filteredPlaygrounds) { playground in
                    NavigationLink(value: playground) {
                        Label(playground.name, systemImage: model.categoryIcon(playground.category))
                    }
                }
            }
        }
        .navigationTitle("Playground Reservation")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Playground.self) { playground in
            FDPlaygroundReservePage(playground)
        }
    }
}

fileprivate struct FDPlaygroundReservePage: View {
    private let playground: Playground
    @State private var showAvailable = false
    @State private var date = Date.now
    
    init(_ playground: Playground) {
        self.playground = playground
    }
    
    var body: some View {
        List {
            Section {
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                Toggle("Available Time Slots Only", isOn: $showAvailable)
            }
            
            AsyncContentView(style: .widget) {
                return try await ReservationStore.shared.getReservations(playground: playground, date: date)
            } content: { reservations in
                let filteredReservations = reservations.filter { $0.available || !showAvailable }
                
                if filteredReservations.isEmpty {
                    Text("No Time Slots Available")
                } else {
                    Grid(alignment: .leading) {
                        ForEach(filteredReservations) { reservation in
                            ReservationView(reservation: reservation)
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
            Text("\(reservation.begin.formatted(date: .omitted, time: .shortened)) - \(reservation.end.formatted(date: .omitted, time: .shortened))")
            Spacer()
            Text("\(reservation.reserved) / \(reservation.total)")
            Spacer()
            if reservation.available {
                Button {
                    showSheet = true
                } label: {
                    Text("Reserve")
                }
            } else if reservation.reserved == reservation.total {
                Text("Full")
                    .foregroundColor(.secondary)
            } else {
                Text("Unavailable")
                    .foregroundColor(.secondary)
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
                    Text("Cannot Reserve")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .navigationTitle("Reserve Page")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
