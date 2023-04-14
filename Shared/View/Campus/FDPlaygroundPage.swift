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
    @StateObject var model: FDPlaygroundModel
    
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
    @StateObject var model: FDReservationModel
    
    init(_ playground: FDPlayground) {
        self._model = StateObject(wrappedValue: FDReservationModel(playground))
    }
    
    var body: some View {
        List {
            Section {
                DatePicker("Select Reservation Date", selection: $model.date, displayedComponents: [.date])
                    .onChange(of: model.date) { date in
                        model.timeSlots = []
                        Task {
                            await model.loadTimeSlots()
                        }
                    }
                Toggle("Available Time Slots Only", isOn: $model.showAvailable)
            }
            
            Section {
                ForEach(model.filteredTimeSlots) { timeSlot in
                    FDReservationTimeSlotView(timeSlot: timeSlot)
                }
                .environmentObject(model)
            } header: {
                Text("Reservation Time Slots")
            } footer: {
                // FIXME: may display error view when timeslot is empty
                if model.timeSlots.isEmpty {
                    LoadingFooter(loading: $model.loading,
                                  errorDescription: model.loadingError?.localizedDescription ?? "",
                                  action: model.loadTimeSlots)
                }
            }
            .task {
                await model.loadTimeSlots()
            }
        }
        .navigationTitle(model.playground.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $model.selectedTimeSlot) { timeSlot in
            FDReservationSheet(timeSlot)
        }
    }
}

fileprivate struct FDReservationTimeSlotView: View {
    @EnvironmentObject var model: FDReservationModel
    let timeSlot: FDPlaygroundTimeSlot
    
    var body: some View {
        HStack {
            Text("\(timeSlot.beginTime) - \(timeSlot.endTime)")
            Spacer()
            Text("\(timeSlot.reserved) / \(timeSlot.total)")
            Spacer()
            if timeSlot.reserveId != nil {
                Button {
                    model.selectedTimeSlot = timeSlot
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
    }
}

fileprivate struct FDReservationSheet: View {
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
