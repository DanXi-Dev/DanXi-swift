import SwiftUI

struct FDPlaygroundPage: View {
    var body: some View {
        AsyncContentView {
            return try await FDPlaygroundModel.load()
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
                    ForEach(model.campusList, id: \.self) { campus in
                        Text(campus).tag(campus)
                    }
                    Text("All").tag("")
                }
                Picker(selection: $model.type, label: Text("Playground Type")) {
                    ForEach(model.typesList, id: \.self) { type in
                        Text(type).tag(type)
                    }
                    Text("All").tag("")
                }
            }
            
            Section("Playground List") {
                ForEach(model.filteredPlaygrounds) { playground in
                    NavigationLink(value: playground) {
                        Label(playground.name, systemImage: model.categoryIcon(playground.type))
                    }
                }
            }
        }
        .navigationTitle("Playground Reservation")
        .navigationDestination(for: FDPlayground.self) { playground in
            FDPlaygroundReservePage(playground)
        }
    }
}

fileprivate struct FDPlaygroundReservePage: View {
    private let playground: FDPlayground
    @State private var showAvailable = true
    @State private var date = Date.now
    
    init(_ playground: FDPlayground) {
        self.playground = playground
    }
    
    var body: some View {
        List {
            Section {
                DatePicker("Select Reservation Date", selection: $date, displayedComponents: [.date])
                Toggle("Available Time Slots Only", isOn: $showAvailable)
            }
            
            AsyncContentView(style: .widget) {
                return try await FDPlaygroundAPI.getTimeSlotList(playground: self.playground, date: self.date)
            } content: { timeSlots in
                let filteredTimeSlots = timeSlots.filter { $0.reserveId != nil || !showAvailable }
                ForEach(filteredTimeSlots) { timeSlot in
                    TimeSlotView(timeSlot: timeSlot)
                }
            }
            .id(date)
        }
        .navigationTitle(playground.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct TimeSlotView: View {
    let timeSlot: FDPlaygroundTimeSlot
    @State private var showSheet = false
    
    var body: some View {
        HStack {
            Text("\(timeSlot.beginTime) - \(timeSlot.endTime)")
            Spacer()
            Text("\(timeSlot.reserved) / \(timeSlot.total)")
            Spacer()
            if timeSlot.reserveId != nil {
                Button {
                    showSheet = true
                } label: {
                    Text("Reserve")
                }
            } else if timeSlot.reserved == timeSlot.total {
                Text("Reserved")
                    .foregroundColor(.secondary)
            } else {
                Text("Cannot Reserve")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showSheet) {
            ReservationSheet(timeSlot)
        }
    }
}

fileprivate struct ReservationSheet: View {
    let timeSlot: FDPlaygroundTimeSlot
    let request: URLRequest?
    
    init(_ timeSlot: FDPlaygroundTimeSlot) {
        self.timeSlot = timeSlot
        if let url = timeSlot.registerURL {
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
            .navigationTitle("Reserve Page")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
